class TimeResult {
  final dynamic returnValue;
  final Duration time;
  TimeResult(this.returnValue, this.time);
}

// Time the given function, returning an object containing the function's return
// value and the execution time
//
// To time function call: foo(1, 2, 3, f: 4, g: 5); Use: time(foo, [1,2,3], {#f:
//   4, #g: 5});
Future<TimeResult> time(Function function,
    [List positionalArguments, Map<Symbol, dynamic> namedArguments]) async {
  final stopwatch = Stopwatch()..start();
  final result =
      await Function.apply(function, positionalArguments, namedArguments);
  return TimeResult(result, stopwatch.elapsed);
}
