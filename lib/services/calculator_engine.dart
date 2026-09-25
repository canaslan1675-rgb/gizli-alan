/// A small but real calculator: + − × ÷, %, decimals, operator precedence,
/// backspace and clear. Pure Dart so it can be unit tested.
///
/// The vault entry is layered on top by the UI: when `=` is pressed and
/// [pinCandidate] is non-null (the whole entry is 4–8 plain digits), the UI
/// asks the AuthService whether it is a PIN. Otherwise `=` just evaluates.
class CalculatorEngine {
  static const operators = {'+', '−', '×', '÷'};

  String _expr = '';
  String _display = '0';
  bool _justEvaluated = false;

  /// What the user typed so far (e.g. `12+3×4`).
  String get expression => _expr;

  /// Main display value.
  String get display => _display;

  /// Non-null when the current entry could be a vault PIN.
  /// Results of a previous `=` never count, only freshly typed digits.
  String? get pinCandidate =>
      !_justEvaluated && RegExp(r'^\d{4,8}$').hasMatch(_expr) ? _expr : null;

  void clear() {
    _expr = '';
    _display = '0';
    _justEvaluated = false;
  }

  void input(String key) {
    if (key == 'C') return clear();
    if (key == '⌫') return _backspace();
    if (key == '=') return evaluate();
    if (key == '%') return _append('%');
    if (operators.contains(key)) return _operator(key);
    if (key == '.' || RegExp(r'^\d$').hasMatch(key)) return _digit(key);
  }

  void _digit(String d) {
    if (_justEvaluated) {
      _expr = '';
      _justEvaluated = false;
    }
    final current = _currentNumber();
    if (d == '.') {
      if (current.contains('.')) return;
      if (current.isEmpty) d = '0.';
    }
    if (current.endsWith('%')) return;
    if (current == '0' && d != '.' && d != '0.') {
      _expr = _expr.substring(0, _expr.length - 1);
    }
    if (current.length >= 15) return;
    _expr += d;
    _display = _preview();
  }

  void _operator(String op) {
    _justEvaluated = false;
    if (_expr.isEmpty) {
      if (op == '−') _expr = '−'; // leading negative number
      return;
    }
    final last = _expr[_expr.length - 1];
    if (operators.contains(last)) {
      _expr = _expr.substring(0, _expr.length - 1);
      if (_expr.isEmpty) return;
    }
    if (_expr.endsWith('.')) _expr = _expr.substring(0, _expr.length - 1);
    _expr += op;
  }

  void _append(String s) {
    if (_expr.isEmpty) return;
    final last = _expr[_expr.length - 1];
    if (operators.contains(last) || last == '%') return;
    _justEvaluated = false;
    _expr += s;
    _display = _preview();
  }

  void _backspace() {
    if (_justEvaluated) return clear();
    if (_expr.isEmpty) return;
    _expr = _expr.substring(0, _expr.length - 1);
    _display = _expr.isEmpty ? '0' : _preview();
  }

  void evaluate() {
    if (_expr.isEmpty) return;
    final value = CalculatorEngine.evaluateExpression(_expr);
    _display = value == null ? 'Error' : format(value);
    _expr = value == null ? '' : _display.replaceAll('-', '−');
    _justEvaluated = true;
  }

  String _currentNumber() {
    final m = RegExp(r'[\d.%]*$').firstMatch(_expr);
    return m?.group(0) ?? '';
  }

  String _preview() {
    final n = _currentNumber();
    return n.isEmpty ? _display : n;
  }

  /// Evaluates an expression using the calculator's symbols. Returns null on
  /// errors such as division by zero or malformed input.
  static double? evaluateExpression(String expr) {
    final tokens = <Object>[]; // double or operator string
    var i = 0;
    var s = expr;
    while (s.isNotEmpty && operators.contains(s[s.length - 1])) {
      s = s.substring(0, s.length - 1);
    }
    while (i < s.length) {
      final c = s[i];
      final unaryMinus = c == '−' && (tokens.isEmpty || tokens.last is String);
      if (RegExp(r'[\d.]').hasMatch(c) || unaryMinus) {
        final start = i;
        i++;
        while (i < s.length && RegExp(r'[\d.]').hasMatch(s[i])) {
          i++;
        }
        final numStr = s.substring(start, i).replaceAll('−', '-');
        var v = double.tryParse(numStr);
        if (v == null) return null;
        while (i < s.length && s[i] == '%') {
          v = v! / 100;
          i++;
        }
        tokens.add(v!);
      } else if (operators.contains(c)) {
        if (tokens.isEmpty || tokens.last is String) return null;
        tokens.add(c);
        i++;
      } else {
        return null;
      }
    }
    if (tokens.isEmpty || tokens.last is String) return null;

    // Pass 1: × ÷
    final pass = <Object>[tokens.first];
    for (var k = 1; k < tokens.length; k += 2) {
      final op = tokens[k] as String;
      final rhs = tokens[k + 1] as double;
      if (op == '×' || op == '÷') {
        final lhs = pass.removeLast() as double;
        if (op == '÷' && rhs == 0) return null;
        pass.add(op == '×' ? lhs * rhs : lhs / rhs);
      } else {
        pass
          ..add(op)
          ..add(rhs);
      }
    }
    // Pass 2: + −
    var result = pass.first as double;
    for (var k = 1; k < pass.length; k += 2) {
      final op = pass[k] as String;
      final rhs = pass[k + 1] as double;
      result = op == '+' ? result + rhs : result - rhs;
    }
    if (result.isNaN || result.isInfinite) return null;
    return result;
  }

  /// Formats a result without trailing zeros (max 10 decimals).
  static String format(double v) {
    if (v == v.truncateToDouble() && v.abs() < 1e15) {
      return v.toInt().toString();
    }
    if (v.abs() >= 1e15 || v.abs() < 1e-9) {
      return v.toStringAsExponential(6);
    }
    var s = v.toStringAsFixed(10);
    s = s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
    return s;
  }
}
