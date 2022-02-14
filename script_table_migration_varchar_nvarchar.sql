set nocount on;

/*

close cur 
deallocate cur

*/

declare @factor decimal(2,1) = 1.5 -- this is important
, @dry_run bit = 0
, @sql nvarchar(max)
, @db sysname
, @test_table sysname

create table #statements (id int identity primary key not null, db sysname, schema_name sysname, table_name sysname, obj_typ sysname, cmd varchar(max), start_dat datetime null, end_dat datetime null)

begin try
declare cur cursor for
	select name from sys.databases where name in ('xxxxxx') 
	-- select name from sys.databases where name in ('ickv_21c_bmt', '21c_ickv_iskv_bmt_temp', '21c_ickv_iskv_bmt', 'ickv_21c', 'digigs_sbk', 'user_orga')
	--> 'lei_ext', 'import_temp', 'DatacenterService' --> diese nicht
	group by name
open cur
	FETCH NEXT FROM cur into @db
	WHILE @@FETCH_STATUS = 0 BEGIN
		set @sql = N'	USE '+quotename(@db)+N';
	declare @_sname sysname, @_tname sysname, @_tname_tmp sysname, @_id sysname = convert(sysname, newid()), @_has_max bit, @_cnt int, @_idx int
	, @_drop_default_constraint varchar(max)
	, @_set_lock_escalation varchar(max)
	, @_add_default_constraint varchar(max)
	, @_create_table varchar(max)
	, @_set_identity_insert_on varchar(max)
	, @_insert_into_temp_table varchar(max)
	, @_set_identity_insert_off varchar(max)
	, @_drop_table varchar(max)
	, @_rename_instead_of_drop_table varchar(max)
	, @_rename_table varchar(max)
	, @_column_list varchar(max)
	, @_column_list_insert varchar(max)
	, @_create_indexes_and_primary_keys varchar(max)

	declare @_rename_default_constraints table(cmd nvarchar(max))
	declare @_tab_indexes_and_primary_keys table (definition nvarchar(max))
	declare @_tab_triggers table(definition nvarchar(max))
	declare @_rename_indexes table(cmd nvarchar(max))

	declare c1 cursor for 
		select s.name, t.name, iif(min(c.max_length)=-1,1,0) as has_max, COUNT(*) over () as cnt, ROW_NUMBER() over (order by s.name, t.name) as rn
		from '+QUOTENAME(@db)+N'.sys.tables t 
		join '+QUOTENAME(@db)+N'.sys.schemas s on s.schema_id = t.schema_id
		join '+QUOTENAME(@db)+N'.sys.columns c on c.object_id = t.object_id
		where t.is_ms_shipped = 0
		and c.system_type_id in (167,175) --varchar,char
		and ('+ISNULL('''' + @test_table + '''','null')+N' = t.name or '+ISNULL('''' + @test_table + '''','null')+N' is null)
		group by s.name, t.name
		order by s.name, t.name
	open c1
		fetch next from c1 into @_sname, @_tname, @_has_max, @_cnt, @_idx
		while @@FETCH_STATUS = 0 begin
			select @_tname_tmp = @_id + ''_'' + @_tname
				, @_drop_default_constraint = N''''
				, @_add_default_constraint = N''''
				, @_set_lock_escalation = N''''
				, @_create_table = N''''
				, @_insert_into_temp_table = N''''
				, @_drop_table = N''''
				, @_rename_instead_of_drop_table = N''''
				, @_rename_table = N''''
				, @_column_list = N''''
				, @_column_list_insert = N''''
				, @_create_indexes_and_primary_keys = N''''
				, @_set_identity_insert_on = N''''
				, @_set_identity_insert_off = N''''

			delete from @_tab_indexes_and_primary_keys
			delete from @_tab_triggers
			delete from @_rename_indexes
			delete from @_rename_default_constraints
				'

		-- 1a: drop default constraints
		-- 1b: add default constraints
		-- 1c: set lock escalation
		set @sql += N'
			select @_add_default_constraint += char(13) + char(10) + ''ALTER TABLE '+QUOTENAME(@db)+N'.''+quotename(@_sname)+''.''+quotename(@_tname_tmp)+'' ADD CONSTRAINT '' + quotename(dc.name) + '' DEFAULT '' + dc.definition + '' FOR '' + quotename(c.name)
				, @_drop_default_constraint += char(13) + char(10) + ''ALTER TABLE '+QUOTENAME(@db)+N'.''+quotename(@_sname)+''.''+quotename(@_tname)+'' DROP CONSTRAINT '' + quotename(dc.name)
				from '+QUOTENAME(@db)+N'.sys.default_constraints dc 
				join '+QUOTENAME(@db)+N'.sys.tables t on t.object_id = dc.parent_object_id and t.name = @_tname
				join '+QUOTENAME(@db)+N'.sys.schemas s on s.schema_id = t.schema_id and s.name = @_sname
				join '+QUOTENAME(@db)+N'.sys.columns c on c.object_id = t.object_id and c.column_id = dc.parent_column_id

			insert into @_rename_default_constraints (cmd)
				select ''EXECUTE '+QUOTENAME(@db)+N'..sp_rename ''''''+@_sname+''.''+dc.name+'''''', ''''''+@_id + ''_'' + dc.name+'''''', ''''OBJECT''''''
				from '+QUOTENAME(@db)+N'.sys.default_constraints dc 
				join '+QUOTENAME(@db)+N'.sys.tables t on t.object_id = dc.parent_object_id and t.name = @_tname
				join '+QUOTENAME(@db)+N'.sys.schemas s on s.schema_id = t.schema_id and s.name = @_sname

			select @_set_lock_escalation = char(13) + char(10) + ''ALTER TABLE  '+QUOTENAME(@db)+N'.''+quotename(@_sname)+''.''+quotename(@_tname_tmp) + '' SET (LOCK_ESCALATION = TABLE)''
				from '+QUOTENAME(@db)+N'.sys.tables t 
				join '+QUOTENAME(@db)+N'.sys.schemas s on s.schema_id = t.schema_id and s.name = @_sname
				where t.name = @_tname
			'
		-- 2a: create table
		-- 2b: create insert statement
		-- 2c: identity_insert on
		-- 2d: identity_insert off
		-- Todo: ON PRIMARY
		set @sql += N'		
			select @_create_table =  char(13) + char(10) + ''CREATE TABLE '+QUOTENAME(@db)+N'.''+quotename(@_sname)+''.''+quotename(@_tname_tmp)+''(''
			select @_set_identity_insert_on = iif(sum(convert(tinyint,c.is_identity)) over() > 0, '' SET IDENTITY_INSERT '+QUOTENAME(@db)+N'.''+quotename(@_sname)+''.''+quotename(@_tname_tmp)+'' ON;'', '''')
				, @_set_identity_insert_off = iif(sum(convert(tinyint,c.is_identity)) over() > 0, '' SET IDENTITY_INSERT '+QUOTENAME(@db)+N'.''+quotename(@_sname)+''.''+quotename(@_tname_tmp)+'' OFF;'', '''')
				, @_create_table += char(13) + char(10) + '' '' + quotename(c.name) + '' '' + case when c.is_computed = 1 then '' AS '' + cc.definition + '', ''
				else iif(ty.name = ''varchar'', ''[nvarchar]'', iif(ty.name = ''char'', ''nchar'', quotename(ty.name))) 
				--+ iif (ty.name in (''varchar'', ''char''), ''(''+iif(c.max_length=-1 or c.max_length > 4000,''max'',convert(sysname,c.max_length))+'')'', iif(ty.name in (''decimal'', ''numeric''), ''(''+convert(sysname,c.precision)+'',''+convert(sysname,c.scale)+'')'', '''')) 
				+ iif (ty.name in (''varchar'', ''char''), ''(''+iif(c.max_length=-1 or c.max_length * ' + convert(sysname, @factor) + ' > 4000,''max'',convert(sysname,convert(int,c.max_length * ' + convert(sysname, @factor) + ')))+'')'', iif(ty.name in (''decimal'', ''numeric''), ''(''+convert(sysname,c.precision)+'',''+convert(sysname,c.scale)+'')'', '''')) 
				+ '' '' + isnull(''identity(''+convert(sysname,ic.seed_value)+'',''+convert(sysname,ic.increment_value)+'')'', '''')
				+ '' '' + iif(c.is_nullable = 1, ''NULL'', ''NOT NULL'') + '','' end
				, @_column_list += quotename(c.name) + '', ''
				, @_column_list_insert += iif(cc.name is null,quotename(c.name) + '', '','''')
				from '+QUOTENAME(@db)+N'.sys.columns c 
				join '+QUOTENAME(@db)+N'.sys.tables t on t.object_id = c.object_id and t.name = @_tname
				join '+QUOTENAME(@db)+N'.sys.schemas s on s.schema_id = t.schema_id and s.name = @_sname
				join '+QUOTENAME(@db)+N'.sys.types ty on ty.system_type_id = c.system_type_id
				left join '+QUOTENAME(@db)+N'.sys.computed_columns cc on cc.object_id = c.object_id and cc.column_id = c.column_id and c.is_computed = 1
				left join '+QUOTENAME(@db)+N'.sys.identity_columns ic on ic.object_id = c.object_id and ic.column_id = c.column_id and c.is_identity = 1
				order by c.column_id
			select @_create_table += '') ON [PRIMARY] ''
			if @_has_max = 1 select @_create_table += ''TEXTIMAGE_ON [PRIMARY]''
			
			set @_column_list_insert = left(@_column_list_insert, len(@_column_list_insert) - 1)
			select @_insert_into_temp_table = ''INSERT INTO '+QUOTENAME(@db)+N'.''+quotename(@_sname)+''.''+quotename(@_tname_tmp)+'' ('' + @_column_list_insert + '') select '' + @_column_list_insert + '' from '+QUOTENAME(@db)+N'.''+quotename(@_sname)+''.''+quotename(@_tname)
			select @_insert_into_temp_table = char(13) + char(10) + ''IF EXISTS (SELECT 1 FROM '+QUOTENAME(@db)+N'.''+quotename(@_sname)+''.''+quotename(@_tname)+'') BEGIN '' + @_insert_into_temp_table + '' END''
			select @_insert_into_temp_table = char(13) + char(10) + @_set_identity_insert_on + char(13) + char(10) + @_insert_into_temp_table + char(13) + char(10) + @_set_identity_insert_off
			'
		-- 3a: drop old table; ToDo: remove foreign key first / save for later - give obj_typ an order 
		set @sql += N'		
			select @_drop_table = char(13) + char(10) + ''DROP TABLE '+QUOTENAME(@db)+N'.''+quotename(@_sname)+''.''+quotename(@_tname)
			'
		-- 3b: Alternative: consider renaming instead of drop
		set @sql += N'		
			select @_rename_instead_of_drop_table = char(13) + char(10) + ''exec '+QUOTENAME(@db)+N'..sp_rename '''''' + @_sname+''.''+@_tname + '''''', ''''x-''+@_id + ''_'' + @_tname +'''''', ''''OBJECT''''''
			'
		-- 4: rename
		set @sql += N'
			select @_rename_table = char(13) + char(10) + ''EXECUTE '+QUOTENAME(@db)+N'..sp_rename ''''''+@_sname+''.''+@_tname_tmp+'''''', ''''''+@_tname+'''''', ''''OBJECT''''''
			'

		-- 4b: rename indexes
		set @sql += N'
			insert into @_rename_indexes (cmd)
			select ''EXECUTE '+QUOTENAME(@db)+N'..sp_rename ''''''+@_sname+''.''+t.name+''.''+i.name+'''''', ''''''+@_id + ''_'' + i.name+'''''', ''''INDEX''''''
			from '+QUOTENAME(@db)+N'.sys.indexes i
			join '+QUOTENAME(@db)+N'.sys.tables t on t.object_id = i.object_id and t.name = @_tname
			join '+QUOTENAME(@db)+N'.sys.schemas s on s.schema_id = t.schema_id and s.name = @_sname
		'
		-- 5: primary keys and indexes
		set @sql += N' 
			insert into @_tab_indexes_and_primary_keys (definition)
			select create_statement = case when i.is_primary_key = 1 
			--then '' ALTER TABLE '+QUOTENAME(@db)+N'.'' + quotename(s.name) + ''.'' + quotename(t.name) 
			then '' ALTER TABLE '+QUOTENAME(@db)+N'.'' + quotename(s.name) + ''.'' + quotename(@_tname_tmp) 
					+ '' ADD CONSTRAINT '' + quotename(i.name) + '' PRIMARY KEY '' 
					+ i.type_desc COLLATE DATABASE_DEFAULT 
					+ '' ( '' +tmp4.KeyColumns+ '' )''
					+ '' WITH (''
					+ ''  STATISTICS_NORECOMPUTE = '' + iif(st.no_recompute = 0, ''OFF'', ''ON'')
					+ '', IGNORE_DUP_KEY = '' + iif(i.ignore_dup_key = 1, ''ON'', ''OFF'')
					+ '', ALLOW_ROW_LOCKS = '' + iif(i.allow_row_locks = 1, ''ON'', ''OFF'')
					+ '', ALLOW_PAGE_LOCKS = '' + iif(i.allow_page_locks = 1, ''ON'', ''OFF'')
					+ '') ON '' + quotename(ds.name)
			else '' CREATE '' + iif(i.is_unique = 1, '' UNIQUE '', '''')
					+ i.type_desc COLLATE DATABASE_DEFAULT + '' INDEX '' + quotename(i.name) 
					--+ '' ON '+QUOTENAME(@db)+N'.'' + quotename(s.name) + ''.'' + quotename(t.name) 
					+ '' ON '+QUOTENAME(@db)+N'.'' + quotename(s.name) + ''.'' + quotename(@_tname_tmp) 
					+ '' ( '' + tmp4.KeyColumns + '' )  ''
					+ ISNULL('' INCLUDE ('' + tmp2.IncludedColumns + '' ) '', '''')
					+ ISNULL('' WHERE  '' + i.filter_definition, '''')
					+ '' WITH (PAD_INDEX = '' + iif(i.is_padded=1,''ON'',''OFF'')
					+ '', FILLFACTOR = '' + iif(i.fill_factor=0,''100'',convert(sysname, i.fill_factor))
					+ '', SORT_IN_TEMPDB = OFF''
					+ '', IGNORE_DUP_KEY = '' + iif(i.ignore_dup_key = 1, ''ON'', ''OFF'')
					+ '', STATISTICS_NORECOMPUTE = '' + iif(st.no_recompute = 0, ''OFF'', ''ON'')
					+ '', ONLINE = OFF''
					+ '', ALLOW_ROW_LOCKS = '' + iif(i.allow_row_locks = 1, ''ON'', ''OFF'')
					+ '', ALLOW_PAGE_LOCKS = '' + iif(i.allow_page_locks = 1, ''ON'', ''OFF'')
					+ '') ON '' + quotename(ds.name)
			end
			FROM '+QUOTENAME(@db)+N'.sys.indexes i
			JOIN '+QUOTENAME(@db)+N'.sys.tables t ON t.object_id = i.object_id
			JOIN '+QUOTENAME(@db)+N'.sys.schemas s on s.schema_id = t.schema_id
			JOIN (
				SELECT ic2.object_id, ic2.index_id, STUFF((
					SELECT '', '' + quotename(c.name)
					+ iif(max(convert(tinyint, ii.is_primary_key)) = 1, '''', iif(max(convert(tinyint, ic1.is_descending_key)) = 1, '' DESC '', '' ASC ''))
					FROM '+QUOTENAME(@db)+N'.sys.index_columns ic1
					JOIN '+QUOTENAME(@db)+N'.sys.indexes ii on ii.object_id = ic1.object_id and ii.index_id = ic1.index_id
					JOIN '+QUOTENAME(@db)+N'.sys.columns c ON c.object_id = ic1.object_id AND c.column_id = ic1.column_id AND ic1.is_included_column = 0
					WHERE ic1.object_id = ic2.object_id	AND ic1.index_id = ic2.index_id
					GROUP BY ic1.object_id, c.name, ic1.index_id
					ORDER BY MAX(ic1.key_ordinal) FOR XML PATH('''')
				), 1, 2, ''''	) KeyColumns
				FROM '+QUOTENAME(@db)+N'.sys.index_columns ic2 
				GROUP BY ic2.object_id, ic2.index_id
			) tmp4 ON i.object_id = tmp4.object_id AND i.Index_id = tmp4.index_id
			JOIN '+QUOTENAME(@db)+N'.sys.stats st ON st.object_id = i.object_id AND st.stats_id = i.index_id
			JOIN '+QUOTENAME(@db)+N'.sys.data_spaces ds ON i.data_space_id = ds.data_space_id
			JOIN '+QUOTENAME(@db)+N'.sys.filegroups fg ON i.data_space_id = fg.data_space_id
			LEFT JOIN (
				SELECT object_id, index_id, IncludedColumns FROM (
					SELECT ic2.object_id, ic2.index_id, STUFF((
						SELECT '' , '' + C.name
						FROM '+QUOTENAME(@db)+N'.sys.index_columns ic1
						JOIN '+QUOTENAME(@db)+N'.sys.columns C ON  C.object_id = ic1.object_id AND C.column_id = ic1.column_id AND ic1.is_included_column = 1
						WHERE ic1.object_id = ic2.object_id AND ic1.index_id = ic2.index_id
						GROUP BY ic1.object_id, C.name, index_id 
						FOR XML PATH('''')
					), 1, 2, '''') IncludedColumns
					FROM '+QUOTENAME(@db)+N'.sys.index_columns ic2 
					GROUP BY ic2.object_id, ic2.index_id
				) tmp1
				WHERE tmp1.IncludedColumns IS NOT NULL
			) tmp2 ON  tmp2.object_id = i.object_id AND tmp2.index_id = i.index_id
			WHERE i.type > 0
			and t.name = @_tname
			and s.name = @_sname
			'

		-- 7: add triggers
		set @sql += N'
				insert into @_tab_triggers (definition) 
				select m.definition
				from '+QUOTENAME(@db)+N'.sys.triggers tr
				join '+QUOTENAME(@db)+N'.sys.tables t on t.object_id = tr.parent_id and t.name = @_tname
				join '+QUOTENAME(@db)+N'.sys.schemas s on s.schema_id = t.schema_id and s.name = @_sname
				join '+QUOTENAME(@db)+N'.sys.sql_modules m on m.object_id = tr.object_id
			'

		-- 8: insert all that stuff into temp-table
		set @sql += N'
			print char(13) + char(10) + ''-- ['' + convert(sysname, @_idx) + '' / '' + convert(sysname, @_cnt) + ''] '' + quotename(@_sname) + ''.'' + quotename(@_tname)

			insert into #statements (db, schema_name, table_name, obj_typ, cmd) 
			values ('''+QUOTENAME(@db)+N''', @_sname, @_tname, ''DDC'', @_drop_default_constraint)
				,  ('''+QUOTENAME(@db)+N''', @_sname, @_tname, ''CTa'', @_create_table)
				,  ('''+QUOTENAME(@db)+N''', @_sname, @_tname, ''SLE'', @_set_lock_escalation)
				,  ('''+QUOTENAME(@db)+N''', @_sname, @_tname, ''ADC'', @_add_default_constraint)
				,  ('''+QUOTENAME(@db)+N''', @_sname, @_tname, ''ITT'', @_insert_into_temp_table)
				,  ('''+QUOTENAME(@db)+N''', @_sname, @_tname, ''DTa'', @_drop_table)
				,  ('''+QUOTENAME(@db)+N''', @_sname, @_tname, ''RDT'', @_rename_instead_of_drop_table)
				,  ('''+QUOTENAME(@db)+N''', @_sname, @_tname, ''RTa'', @_rename_table)
				--,  ('''+QUOTENAME(@db)+N''', @_sname, @_tname, ''IOn'', @_set_identity_insert_on)
				--,  ('''+QUOTENAME(@db)+N''', @_sname, @_tname, ''IOf'', @_set_identity_insert_off)
			insert into #statements (db, schema_name, table_name, obj_typ, cmd) 
				select '''+QUOTENAME(@db)+N''', @_sname, @_tname, ''RDC'', cmd from @_rename_default_constraints
			insert into #statements (db, schema_name, table_name, obj_typ, cmd) 
				select '''+QUOTENAME(@db)+N''', @_sname, @_tname, ''RIx'', cmd from @_rename_indexes
			insert into #statements (db, schema_name, table_name, obj_typ, cmd) 
				select '''+QUOTENAME(@db)+N''', @_sname, @_tname, ''TRG'', definition from @_tab_triggers
			insert into #statements (db, schema_name, table_name, obj_typ, cmd) 
				select '''+QUOTENAME(@db)+N''', @_sname, @_tname, ''IPK'', definition from @_tab_indexes_and_primary_keys

			fetch next from c1 into @_sname, @_tname, @_has_max, @_cnt, @_idx
		end
	close c1
	deallocate c1'

		-- print long @sql
		declare @idx int = 0, @size int = 4000
		while len(@sql) > @idx begin
			--select len(@sql) _len, @idx idx, @size size
			print substring(@sql, @idx, @idx + @size)
			set @idx += @size
		end
		select LEN(@sql)
		exec sp_executesql @stmt = @sql

		FETCH NEXT FROM cur into @db
	end
close cur
deallocate cur

declare @prio table (obj_typ sysname, prio tinyint, description sysname)
insert into @prio (obj_typ, prio, description) values
  --('DDC', 09, 'DropDefault Constraint') -- disabled: we rename
  ('RDC', 10, 'Rename Default Constraint')
, ('RIx', 11, 'Rename Index')
, ('CTa', 20, 'Create Table')
, ('SLE', 21, 'Set Lock Escalation')
, ('ADC', 22, 'Add Default Constraints')
, ('ITT', 30, 'Insert into Temp Table')
, ('IPK', 31, 'Indexes and Primary Keys')
--, ('DTa', 40, 'Drop Table')
, ('RDT', 41, 'Rename instead of Drop Table')
, ('RTa', 50, 'Rename Table')

select * from #statements s join @prio p on p.obj_typ = s.obj_typ order by s.table_name, p.prio, s.id

-- do it!
declare @id int, @type sysname
declare cur cursor for 
	select s.db, s.cmd, s.id, s.obj_typ from #statements s
	join @prio p on p.obj_typ = s.obj_typ 
	where 1=1
	and table_name like @test_table or @test_table is null 
	order by s.table_name, p.prio, s.id
open cur
	fetch next from cur into @db, @sql, @id, @type
	while @@FETCH_STATUS = 0 begin
		update #statements set start_dat = getdate() where id = @id
		if @type = 'TRG' begin
			set @sql = 'exec ' +@db+ '..sp_executesql N''' +replace(@sql,'''','''''')+ N'''' -- create trigger must be the first statement in the batch
		end	
		print @sql
		if @dry_run = 0 begin
			exec sp_executesql @stmt = @sql
		end
		update #statements set end_dat = getdate() where id = @id

		fetch next from cur into @db, @sql, @id, @type
	end
close cur 
deallocate cur

select * from #statements s join @prio p on p.obj_typ = s.obj_typ order by s.table_name, p.prio, s.id

end try
begin catch
	SELECT ERROR_NUMBER() AS ErrorNumber  
		,ERROR_SEVERITY() AS ErrorSeverity  
		,ERROR_STATE() AS ErrorState  
		,ERROR_PROCEDURE() AS ErrorProcedure  
		,ERROR_LINE() AS ErrorLine  
		,ERROR_MESSAGE() AS ErrorMessage;  
end catch

drop table #statements


---- umgesetzt:
-- dynamic db, tables
-- drop default constraints
----> rename default constraints
-- create default constraints
-- create table
---- varchar -> nvarchar
---- char -> nchar
---- max_length > 4000 / -1 --> max --> Todo: Factor 1.5 / recherche
---- calculated columns
---- identity_insert
-- set lock escalation
-- insert into table
-- rename table
-- create trigger
-- create primary keys
-- create indexes
---- included columns

---- offene punkte:
-- index/primary key length > 900 -- done
----> auswertung - individuell / manuell vorher fixen
----> falls das in der migration vorkommt: varchar lassen

-- consider creating objects before renaming / name collisions
----> done, we just rename for now
-- foreign keys
-- on primary
-- stored procedures / functions / triggers: declare @var varchar(..) select @a = 'char' -> mut zur lücke
----> mssql python / 1 script per procedure / function (file-based?)
-- exclude / include columns? -> das würde stored procedures etc. stark erschweren: Entscheidung: pauschal
-- collation: hat sich erledigt, ist nur zur Repräsentation und Sortierung bei VARCHAR
