import 'dart:typed_data';

import 'proto/dart/sec0.pb.dart';
import 'proto/dart/session.pb.dart';
import 'security.dart';

/// An implementation of the ~no security (Security0) protocol for ESP Provisioning.
///
/// It is inspired heavily by:
/// https://github.com/espressif/esp-idf-provisioning-android/blob/master/provisioning/src/main/java/com/espressif/provisioning/security/Security0.java.
class Security0 implements ProvSecurity {
  final bool verbose;
  SecurityState sessionState;

  Security0({this.sessionState = SecurityState.REQUEST1, this.verbose = false});

  void _verbose(dynamic data) {
    if (verbose) {
      print('+++ $data +++');
    }
  }

  @override
  Future<Uint8List?> encrypt(Uint8List? data) async {
    _verbose('raw before process ${data.toString()}');
    return data;
  }

  @override
  Future<Uint8List?> decrypt(Uint8List? data) async {
    return data;
  }

  @override
  Future<SessionData?> securitySession({SessionData? responseData}) async {
    switch (sessionState) {
      case SecurityState.REQUEST1:
        sessionState = SecurityState.RESPONSE2;
        return await setup0Request();
      case SecurityState.RESPONSE2:
        sessionState = SecurityState.FINISH;
        return await setup0Response(responseData!);
      case SecurityState.FINISH:
        return null;
      default:
        throw Exception('Unexpected state - ${sessionState.toString()}');
    }
  }

  Future<SessionData?> setup0Request() async {
    _verbose('setup0Request');
    var setupRequest = SessionData();
    setupRequest.secVer = SecSchemeVersion.SecScheme0;
    ;
    setupRequest.sec0 = Sec0Payload();
    return setupRequest;
  }

  Future<SessionData?> setup0Response(SessionData responseData) async {
    _verbose('setup0Response');
    var setupResp = responseData;
    if (setupResp.secVer == SecSchemeVersion.SecScheme0) {
      return null;
    } else {
      throw Exception('Unexpected secVer - ${setupResp.secVer.toString()}');
    }
  }
}
