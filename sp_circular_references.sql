
if not exists(select 1 from sys.procedures where name = 'sp_circular_references')
	exec sp_executesql @stmt = N'create procedure sp_circular_references as begin return 0 end;'
go

alter procedure sp_circular_references (
	@table_name sysname,
	@column_name sysname,
	@column_name_parent sysname,
	@value sysname,
	@value_parent sysname
)
as begin
	declare @counter int
	declare @sql nvarchar(max)

	-- -4: check if parent = child
	if @value = @value_parent
		return -4
	-- -3: check if parent id exists
	set @sql = N'select @_c = count(*) from ' + quotename(@table_name) + N' where ' + quotename(@column_name) + N' = ''' + @value_parent + N''''
	--print @sql
	exec sp_executesql @stmt = @sql, @params = N'@_c int out', @_c = @counter out
	if @counter = 0
		return -3
	-- -2: check if there is already a circular reference in the base table
	-- -1: check if new values would cause a circular reference
	create table #results (parent sysname, child sysname, lvl int)
	set @sql = N'; with cte (parent, child, lvl) as (
		select ' + quotename(@column_name_parent) + ' as parent, ' + quotename(@column_name) + N' as child, 0 as lvl from ' + quotename(@table_name) + N' tt
		where not exists(select 1 from ' + quotename(@table_name) + N' where ' + quotename(@column_name) + N' = tt.' + quotename(@column_name_parent) + N')
		union all
		select t.' + quotename(@column_name_parent) + N', t.' + quotename(@column_name) + N', c.[lvl] + 1 as [lvl]
		from cte c
		join ' + quotename(@table_name) + N' t on t.' + quotename(@column_name_parent) + N' = c.[child]
	)
	insert into #results(parent, child, lvl)
	select parent, child, lvl from cte c
	where [child] = ''' + @value_parent + N'''
	and exists(select 1 from cte where [parent] = ''' + @value + N''' and [lvl] <= c.[lvl])'
	
	--print @sql

	exec sp_executesql @stmt = @sql

	select @counter = COUNT(*) from #results
	if @counter > 0 
		return -1

	return 0

end
go
