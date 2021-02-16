<Query Kind="Program" />

//https://haacked.com/archive/2012/07/23/get-all-types-in-an-assembly.aspx/
void Main()
{
	foreach(var t in GetTypesWithInterface<test.IHealthCheck>(Assembly.GetExecutingAssembly()))
	{
		var x = (test.IHealthCheck)Activator.CreateInstance(t);
		x.Check().Dump();
	}
}

private IEnumerable<Type> GetTypesWithInterface<T>(Assembly asm)
{
	var it = typeof(T);
	return asm.GetLoadableTypes()
		.Where(it.IsAssignableFrom)
		.Where(i => i.IsClass);
}

public static class TypeLoaderExtensions {
    public static IEnumerable<Type> GetLoadableTypes(this Assembly assembly) {
        if (assembly == null) throw new ArgumentNullException("assembly");
        try {
            return assembly.GetTypes();
        } catch (ReflectionTypeLoadException e) {
            return e.Types.Where(t => t != null);
        }
    }
}

namespace test
{
	public interface IHealthCheck
	{
		string Check();
	}
	
	public class A : IHealthCheck
	{
		public string Check() => "I am A";
	}
	
	public class B : IHealthCheck
	{
		public string Check() => "I am B";
	}
	
	public class C : IHealthCheck
	{
		public string Check() => "I am C";
	}
}
