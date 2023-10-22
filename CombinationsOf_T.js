// define a class
class MyObject {
    constructor(p1, p2, p3, p4, p5, p6, p7, p8, p9, p10) {
    this.Prop01 = p1;
    this.Prop02 = p2;
    this.Prop03 = p3;
    this.Prop04 = p4;
    this.Prop05 = p5;
    this.Prop06 = p6;
    this.Prop07 = p7;
    this.Prop08 = p8;
    this.Prop09 = p9;
    this.Prop10 = p10;
  };
}

// define a template instance
var obj = new MyObject("A", "B", "C", 100, 200, 400, 800, "X", "Y", "Z");

// some calculations
const properties = Object.keys(obj);
const propCount = properties.length;
var combinations = 1 << propCount;
console.log(propCount, combinations);

// prepare result
var result = [];

// iterate through combinations
for (var i = 1; i < combinations; i++)
{
  var instance = new MyObject();
  var bits = i;
  for (var p = 0; p < properties.length; p++)
  {
  	const prop = properties[p];
    instance[prop] = (bits % 2 == 1) ? obj[prop] : null; // even: set null, odd: set value
    bits = bits >> 1;
  }
  result.push(instance);
}

// some output, do something with it
console.log(result.length, JSON.stringify(result));
