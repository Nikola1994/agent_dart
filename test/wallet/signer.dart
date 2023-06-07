import 'dart:convert';

import 'package:agent_dart/agent/crypto/index.dart';
import 'package:agent_dart/utils/extension.dart';
import 'package:agent_dart/wallet/phrase.dart';
import 'package:agent_dart/wallet/signer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('encodes properly', () async {
    const mne2 = 'open jelly jeans corn ketchup supreme brief element '
        'armed lens vault weather original scissors rug priority '
        'vicious lesson raven spot gossip powder person volcano';
    final acc2CreateTime = DateTime.now();
    final acc2 = await ICPSigner.fromPhrase(mne2, curveType: CurveType.all);
    final acc2TimePeriod = DateTime.now().millisecondsSinceEpoch -
        acc2CreateTime.millisecondsSinceEpoch;

    final acc21CreateTime = DateTime.now();
    final acc21 = await ICPSigner.fromPhrase(mne2);
    final acc21TimePeriod = DateTime.now().millisecondsSinceEpoch -
        acc21CreateTime.millisecondsSinceEpoch;

    final acc22CreateTime = DateTime.now();
    final acc22 =
        await ICPSigner.fromPhrase(mne2, curveType: CurveType.secp256k1);
    final acc22TimePeriod = DateTime.now().millisecondsSinceEpoch -
        acc22CreateTime.millisecondsSinceEpoch;

    expect(acc21TimePeriod < acc2TimePeriod, true);
    expect(acc22TimePeriod < acc2TimePeriod, true);
    expect(acc2.account.identity != null, true);
    expect(acc2.account.ecIdentity != null, true);
    expect(acc21.account.ecIdentity, null);
    expect(acc22.account.identity, null);

    expect(
      acc2.account.ecKeys?.accountId!.toHex(),
      '02f2326544f2040d3985e31db5e7021402c541d3cde911cd20e951852ee4da47',
    );
    expect(
      acc2.account.identity?.getAccountId().toHex(),
      '2636e2e67910af41c53cddb31862f0fa2c31cbd58db9645d90ffb875c7abc8c9',
    );

    await acc2.lock('123');
    expect(acc2.isLocked, true);
    expect(acc2.account.identity, null);
    expect(acc2.account.ecKeys, null);

    await acc2.unlock('123');
    expect(acc2.isLocked, false);
    expect(
      acc2.account.identity?.getAccountId().toHex(),
      '2636e2e67910af41c53cddb31862f0fa2c31cbd58db9645d90ffb875c7abc8c9',
    );
    expect(
      acc2.account.ecKeys?.accountId!.toHex(),
      '02f2326544f2040d3985e31db5e7021402c541d3cde911cd20e951852ee4da47',
    );

    final encryptedPhrase = await encodePhrase(mne2, password: '123');
    final decryptedPhrase = await decodePhrase(
      jsonDecode(encryptedPhrase),
      '123',
    );
    expect(decryptedPhrase, mne2);

    final encryptedCborPhrase1 = await encryptCborPhrase(mne2);
    final decryptedCborPhrase1 = await decryptCborPhrase(encryptedCborPhrase1);
    expect(decryptedCborPhrase1, mne2);

    final encryptedCborPhrase2 = await encryptCborPhrase(mne2, password: '123');
    final decryptedCborPhrase2 = await decryptCborPhrase(
      encryptedCborPhrase2,
      password: '123',
    );
    expect(decryptedCborPhrase2, mne2);

    final p = Phrase.fromString(mne2);
    expect(p.mnemonic, mne2);
    expect(p.list, stringToList(mne2));

    try {
      Phrase.fromString(mne2.substring(0, mne2.length - 10));
    } catch (e) {
      expect((e as PhaseException).toString().contains('pers'), true);
    }

    try {
      Phrase.fromString(mne2.substring(0, mne2.length - 7));
    } catch (e) {
      expect((e as PhaseException).toString().contains('length of 23'), true);
    }
  });
}
