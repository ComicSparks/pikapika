import 'package:event/event.dart';
import 'package:pikapika/basic/Method.dart';

import '../Entities.dart';

bool get isPro {
  return true;
}

ProInfoAf get proInfoAf => _proInfoAll.proInfoAf;
ProInfoPat get proInfoPat => _proInfoAll.proInfoPat;

final proEvent = Event();
late ProInfoAll _proInfoAll;

Future reloadIsPro() async {
  _proInfoAll = await method.proInfoAll();
  proEvent.broadcast();
}
