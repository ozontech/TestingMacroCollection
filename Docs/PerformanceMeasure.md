# PerformanceMeasure

The `PerformanceMeasure` macro allows you to measure the execution time of a code block in milliseconds.
Example:

```
let time = #performanceMeasure {
    doWork()
}
print("Время выполнения блока кода: \(time) мс.")

```

Expanded macro:

```
let time = {
    let startTime = CFAbsoluteTimeGetCurrent()
    doWork()
    return Double(CFAbsoluteTimeGetCurrent() - startTime) * 1000
}()
print("Время выполнения блока кода: \(time) мс.")

```
