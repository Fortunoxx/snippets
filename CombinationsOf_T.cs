	System.Collections.Generic.IEnumerable<T> CombinationsOf<T>(T template) where T : new()
	{
		var properties = typeof(T).GetProperties().Where(prop => prop.CanRead && prop.CanWrite).ToArray();
		if (properties.Length > 31)
		{
		    throw new ObjectTooBigException();
		}

		var combinations = 1 << properties.Length;
		var result = new System.Collections.Generic.List<T>(combinations - 1);
		for (var i = 1; i < combinations; i++)
		{
		    // var instance = (T)Activator.CreateInstance(typeof(T));
		    var instance = new T();
		    var bits = i;
		    for (var p = 0; p < properties.Length; p++)
		    {
		        properties[p].SetValue(instance, (bits % 2 == 1) ? properties[p].GetValue(template) : properties[p].PropertyType.IsValueType ? Activator.CreateInstance(properties[p].PropertyType) : null);
		        bits = bits >> 1;
		    }

		    result.Add(instance);
		}

		return result;
	}

	class ObjectTooBigException : System.Exception
	{
		public override string Message => "Your object is too big.";
	}
