/// A small but real calculator: + − × ÷, %, ±, decimals, operator
/// precedence, repeated `=`, backspace and clear. Pure Dart so it can be
/// unit tested.
///
/// The vault entry is layered on top by the UI: when `=` is pressed and
/// [pinCandidate] is non-null (the whole entry is 4–8 freshly typed digits),
/// the UI asks the AuthService whether it is a PIN. If it is not a PIN, `=`
/// just evaluates (the number itself), exactly like a normal calculator.
///
/// Semantics (match common phone calculators):
/// * `a + b%` / `a − b%` = a ± (a·b/100); `a × b%` = a·(b/100); `b%` = b/100.
/// * `=` again repeats the last operation (`2 + 3 = =` → 8).
/// * Chaining from a result keeps full precision (`1 ÷ 3 = × 3 =` → 1).
/// * Division by zero → "Error", never a crash.
class CalculatorEngine {
  static const operators = {'+', '−', '×', '÷'};
  static const error = 'Error';
  static const maxDigits = 15;

  String _expr = '';
  String _display = '0';
  bool _justEvaluated = false;

  /// Exact value behind the formatted result that starts [_expr].
  ({String text, double value})? _carry;
  String? _repeatOp;
  double? _repeatOperand;

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
    _carry = null;
    _repeatOp = null;
    _repeatOperand = null;
  }

  void input(String key) {
    if (key == 'C') return clear();
    if (key == '⌫') return _backspace();
    if (key == '=') return evaluate();
    if (key == '%') return _percent();
    if (key == '±') return _toggleSign();
    if (operators.contains(key)) return _operator(key);
    if (key == '.' || RegExp(r'^\d$').hasMatch(key)) return _digit(key);
  }

  void _startFresh() {
    _expr = '';
    _carry = null;
    _justEvaluated = false;
  }

  void _digit(String d) {
    if (_justEvaluated) _startFresh();
    final current = _currentNumber();
    if (current.endsWith('%')) return;
    if (d == '.') {
      if (current.contains('.')) return;
      if (current.isEmpty) d = '0.';
    } else if (current == '0') {
      // No leading zeros: "0" + "7" → "7".
      _expr = _expr.substring(0, _expr.length - 1);
    }
    if (current.replaceAll('.', '').length >= maxDigits) return;
    _expr += d;
    _display = _preview();
  }

  void _operator(String op) {
    if (_display == error && _expr.isEmpty) return;
    _justEvaluated = false;
    if (_expr.isEmpty) {
      if (op == '−') _expr = '−'; // leading negative number
      return;
    }
    // Typing an operator twice replaces it.
    while (_expr.isNotEmpty && operators.contains(_expr[_expr.length - 1])) {
      _expr = _expr.substring(0, _expr.length - 1);
    }
    if (_expr.isEmpty) return;
    if (_expr.endsWith('.')) {
      _expr = _expr.substring(0, _expr.length - 1);
      _display = _preview();
    }
    _expr += op;
  }

  void _percent() {
    if (_expr.isEmpty) return;
    final last = _expr[_expr.length - 1];
    if (operators.contains(last) || last == '%' || last == '.') return;
    _justEvaluated = false;
    _expr += '%';
    _display = _preview();
  }

  void _toggleSign() {
    if (_display == error && _expr.isEmpty) return;
    if (_justEvaluated || (_carry != null && _expr == _carry!.text)) {
      final c = _carry;
      if (c == null) return;
      final v = -c.value;
      _display = format(v);
      _expr = _display.replaceAll('-', '−');
      _carry = (text: _expr, value: v);
      return;
    }
    final num = RegExp(r'[\d.]+%?$').firstMatch(_expr);
    if (num == null) return; // nothing typed for the current number yet
    final start = num.start;
    final before = start > 0 ? _expr[start - 1] : '';
    final unary =
        before == '−' && (start == 1 || operators.contains(_expr[start - 2]));
    if (unary) {
      _expr = _expr.substring(0, start - 1) + _expr.substring(start);
    } else {
      _expr = '${_expr.substring(0, start)}−${_expr.substring(start)}';
    }
    _display = _preview();
  }

  void _backspace() {
    if (_justEvaluated) return clear();
    if (_expr.isEmpty) return;
    _expr = _expr.substring(0, _expr.length - 1);
    if (_carry != null && !_expr.startsWith(_carry!.text)) _carry = null;
    _display = _expr.isEmpty ? '0' : _preview();
  }

  void evaluate() {
    if (_justEvaluated) {
      // Repeated "=": apply the last operation again.
      final c = _carry;
      if (c == null || _repeatOp == null) return;
      final v = _apply(c.value, _repeatOp!, _repeatOperand!);
      _setResult(v);
      return;
    }
    var s = _expr;
    while (s.isNotEmpty && operators.contains(s[s.length - 1])) {
      s = s.substring(0, s.length - 1);
    }
    if (s.isEmpty || s == '−') return;
    final tokens = _tokenize(s, _carry);
    final value = tokens == null ? null : _evaluateTokens(tokens);
    if (tokens != null && value != null && tokens.length >= 3) {
      _repeatOp = tokens[tokens.length - 2] as String;
      final last = tokens.last as _Num;
      _repeatOperand = last.percent ? last.value / 100 : last.value;
    } else {
      _repeatOp = null;
      _repeatOperand = null;
    }
    _setResult(value);
  }

  void _setResult(double? value) {
    _justEvaluated = true;
    if (value == null) {
      _display = error;
      _expr = '';
      _carry = null;
      _repeatOp = null;
      return;
    }
    _display = format(value);
    _expr = _display.replaceAll('-', '−');
    _carry = (text: _expr, value: value);
  }

  String _currentNumber() {
    final m = RegExp(r'[\d.%]*$').firstMatch(_expr);
    return m?.group(0) ?? '';
  }

  String _preview() {
    final m = RegExp(r'[\d.]+%?$').firstMatch(_expr);
    if (m == null) return _display;
    final start = m.start;
    final neg =
        start > 0 &&
        _expr[start - 1] == '−' &&
        (start == 1 || operators.contains(_expr[start - 2]));
    return '${neg ? '-' : ''}${m.group(0)}';
  }

  /// Evaluates an expression using the calculator's symbols. Returns null on
  /// errors such as division by zero or malformed input.
  static double? evaluateExpression(String expr) {
    var s = expr;
    while (s.isNotEmpty && operators.contains(s[s.length - 1])) {
      s = s.substring(0, s.length - 1);
    }
    final tokens = _tokenize(s, null);
    return tokens == null ? null : _evaluateTokens(tokens);
  }

  static final _numRe = RegExp(r'^[\d.]+(e[+\-−]?\d+)?');

  static List<Object>? _tokenize(
    String s,
    ({String text, double value})? carry,
  ) {
    final tokens = <Object>[]; // _Num or operator string
    var i = 0;
    if (carry != null &&
        s.startsWith(carry.text) &&
        (s.length == carry.text.length ||
            operators.contains(s[carry.text.length]) ||
            s[carry.text.length] == '%')) {
      i = carry.text.length;
      var pct = false;
      if (i < s.length && s[i] == '%') {
        pct = true;
        i++;
      }
      tokens.add(_Num(carry.value, pct));
    }
    while (i < s.length) {
      final c = s[i];
      final unaryMinus = c == '−' && (tokens.isEmpty || tokens.last is String);
      if (RegExp(r'[\d.]').hasMatch(c) || unaryMinus) {
        final negative = unaryMinus;
        if (unaryMinus) i++;
        final m = _numRe.firstMatch(s.substring(i));
        if (m == null) return null;
        final v = double.tryParse(m.group(0)!.replaceAll('−', '-'));
        if (v == null) return null;
        i += m.group(0)!.length;
        var pct = false;
        if (i < s.length && s[i] == '%') {
          pct = true;
          i++;
        }
        tokens.add(_Num(negative ? -v : v, pct));
      } else if (operators.contains(c)) {
        if (tokens.isEmpty || tokens.last is String) return null;
        tokens.add(c);
        i++;
      } else {
        return null;
      }
    }
    if (tokens.isEmpty || tokens.last is String) return null;
    return tokens;
  }

  static double? _evaluateTokens(List<Object> tokens) {
    // Pass 1: × ÷ (percent operands are plain /100 here).
    final pass = <Object>[tokens.first];
    for (var k = 1; k < tokens.length; k += 2) {
      final op = tokens[k] as String;
      final rhs = tokens[k + 1] as _Num;
      if (op == '×' || op == '÷') {
        final lhs = (pass.removeLast() as _Num).plain;
        final r = rhs.plain;
        if (op == '÷' && r == 0) return null;
        pass.add(_Num(op == '×' ? lhs * r : lhs / r, false));
      } else {
        pass
          ..add(op)
          ..add(rhs);
      }
    }
    // Pass 2: + − (a ± b% = a ± a·b/100).
    var result = (pass.first as _Num).plain;
    for (var k = 1; k < pass.length; k += 2) {
      final op = pass[k] as String;
      final rhs = pass[k + 1] as _Num;
      final r = rhs.percent ? result * rhs.value / 100 : rhs.value;
      result = op == '+' ? result + r : result - r;
    }
    if (result.isNaN || result.isInfinite) return null;
    return result;
  }

  static double? _apply(double a, String op, double b) {
    final double r;
    switch (op) {
      case '+':
        r = a + b;
      case '−':
        r = a - b;
      case '×':
        r = a * b;
      default:
        if (b == 0) return null;
        r = a / b;
    }
    return r.isNaN || r.isInfinite ? null : r;
  }

  /// Formats a result: integers plainly, decimals rounded to at most 15
  /// significant digits / 10 decimals with trailing zeros removed (so
  /// 0.1 + 0.2 shows 0.3), very large/small values in e-notation.
  static String format(double v) {
    if (v == 0) return '0';
    final a = v.abs();
    if (a >= 1e15 || a < 1e-9) {
      final s = v.toStringAsExponential(8);
      final parts = s.split('e');
      final mantissa = parts[0]
          .replaceFirst(RegExp(r'0+$'), '')
          .replaceFirst(RegExp(r'\.$'), '');
      return '${mantissa}e${parts[1]}';
    }
    final intDigits = a < 1 ? 1 : a.floor().toString().length;
    final decimals = (15 - intDigits).clamp(0, 10);
    var s = v.toStringAsFixed(decimals);
    if (s.contains('.')) {
      s = s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
    }
    return s == '-0' ? '0' : s;
  }
}

class _Num {
  const _Num(this.value, this.percent);
  final double value;
  final bool percent;
  double get plain => percent ? value / 100 : value;
}
