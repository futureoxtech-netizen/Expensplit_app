import 'package:expense_app/core/balances/balance_calculator.dart';
import 'package:expense_app/core/balances/split_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('computeShares', () {
    test('equal split divides evenly with residual on first', () {
      final s = computeShares(total: 100, mode: 'equal', splits: [
        {'userId': 'a'},
        {'userId': 'b'},
        {'userId': 'c'},
      ]);
      expect(s.map((e) => e.amount).reduce((a, b) => a + b), closeTo(100, 0.001));
      expect(s.length, 3);
    });

    test('percent must sum to 100', () {
      expect(
        () => computeShares(total: 100, mode: 'percent', splits: [
          {'userId': 'a', 'value': 50},
        ]),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('exact must sum to total', () {
      final s = computeShares(total: 90, mode: 'exact', splits: [
        {'userId': 'a', 'value': 60},
        {'userId': 'b', 'value': 30},
      ]);
      expect(s.firstWhere((e) => e.userId == 'a').amount, 60);
    });
  });

  group('resolvePayers', () {
    test('single payer when one contributor', () {
      final r = resolvePayers(paidBy: 'a', payers: const [], total: 90);
      expect(r.paidBy, 'a');
      expect(r.payers, isEmpty);
    });

    test('multi payer must sum to total; primary is largest', () {
      final r = resolvePayers(paidBy: 'a', total: 90, payers: [
        {'userId': 'a', 'amount': 60},
        {'userId': 'b', 'amount': 30},
      ]);
      expect(r.payers.length, 2);
      expect(r.paidBy, 'a'); // largest contributor
    });

    test('multi payer mismatch throws', () {
      expect(
        () => resolvePayers(paidBy: 'a', total: 90, payers: [
          {'userId': 'a', 'amount': 60},
          {'userId': 'b', 'amount': 10},
        ]),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('groupNets + simplifyDebts', () {
    test('single payer: B and C each owe A 30', () {
      final nets = groupNets(
        ['a', 'b', 'c'],
        [
          ExpenseCalc(
            payers: [PayerAmt('a', 90)],
            shares: [PayerAmt('a', 30), PayerAmt('b', 30), PayerAmt('c', 30)],
          ),
        ],
        const [],
      );
      expect(nets['a'], closeTo(60, 0.001));
      expect(nets['b'], closeTo(-30, 0.001));
      final transfers = simplifyDebts(nets);
      expect(transfers.length, 2);
      expect(transfers.every((t) => t.to == 'a'), isTrue);
    });

    test('settlement reduces balance', () {
      final nets = groupNets(
        ['a', 'b'],
        [
          ExpenseCalc(payers: [PayerAmt('a', 100)], shares: [PayerAmt('a', 50), PayerAmt('b', 50)]),
        ],
        [SettlementCalc(from: 'b', to: 'a', amount: 50)],
      );
      expect(nets['a'], closeTo(0, 0.001));
      expect(nets['b'], closeTo(0, 0.001));
    });
  });

  group('pairwiseNet (multi-payer proportional allocation)', () {
    final calc = ExpenseCalc(
      payers: [PayerAmt('a', 60), PayerAmt('b', 30)],
      shares: [PayerAmt('a', 30), PayerAmt('b', 30), PayerAmt('c', 30)],
    );
    test('C owes A 20 (30 * 60/90)', () {
      expect(pairwiseNet(calc, 'a', 'c'), closeTo(20, 0.001));
    });
    test('C owes B 10 (30 * 30/90)', () {
      expect(pairwiseNet(calc, 'b', 'c'), closeTo(10, 0.001));
    });
    test('A vs B nets to +10 for A', () {
      expect(pairwiseNet(calc, 'a', 'b'), closeTo(10, 0.001));
    });
  });
}
