/// key : "/cyber/go/track-toolbox-v0.13.7"
/// monitor : false
/// logs : [{"timestamp":"2023-09-28T15:18:44.755146676","ip":"111.172.5.148","ipInfo":"中国|0|湖北省|武汉市|电信","request-method":"get","scheme":"http","server-name":"go.mazhangjing.com","server-port":80,"ip-tag":null},{"timestamp":"2023-09-28T11:24:16.712078418","ip":"111.172.5.148","ipInfo":"中国|0|湖北省|武汉市|电信","request-method":"get","scheme":"http","server-name":"go.mazhangjing.com","server-port":80,"ip-tag":null},{"timestamp":"2023-09-27T17:45:19.660794478","ip":"111.172.5.148","ipInfo":"中国|0|湖北省|武汉市|电信","request-method":"get","scheme":"http","server-name":"go.mazhangjing.com","server-port":80,"ip-tag":null}]

class Track {
  Track({
    String? key,
    bool? monitor,
    List<Logs>? logs,
  }) {
    _key = key;
    _monitor = monitor;
    _logs = logs;
  }

  Track.fromJson(dynamic json) {
    _key = json['key'];
    _monitor = json['monitor'];
    if (json['logs'] != null) {
      _logs = [];
      json['logs'].forEach((v) {
        _logs?.add(Logs.fromJson(v));
      });
    }
  }

  String? _key;
  bool? _monitor;
  List<Logs>? _logs;

  Track copyWith({
    String? key,
    bool? monitor,
    List<Logs>? logs,
  }) =>
      Track(
        key: key ?? _key,
        monitor: monitor ?? _monitor,
        logs: logs ?? _logs,
      );

  String? get key => _key;

  bool? get monitor => _monitor;

  List<Logs>? get logs => _logs;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['key'] = _key;
    map['monitor'] = _monitor;
    if (_logs != null) {
      map['logs'] = _logs?.map((v) => v.toJson()).toList();
    }
    return map;
  }

  @override
  String toString() {
    return 'Track{_key: $_key, _monitor: $_monitor, _logs: $_logs}';
  }
}

/// timestamp : "2023-09-28T15:18:44.755146676"
/// ip : "111.172.5.148"
/// ipInfo : "中国|0|湖北省|武汉市|电信"
/// request-method : "get"
/// scheme : "http"
/// server-name : "go.mazhangjing.com"
/// server-port : 80
/// ip-tag : null

class Logs {
  Logs({
    String? timestamp,
    String? ip,
    String? ipInfo,
    String? requestmethod,
    String? scheme,
    String? servername,
    num? serverport,
    dynamic iptag,
  }) {
    _timestamp = timestamp;
    _ip = ip;
    _ipInfo = ipInfo;
    _requestmethod = requestmethod;
    _scheme = scheme;
    _servername = servername;
    _serverport = serverport;
    _iptag = iptag;
  }

  Logs.fromJson(dynamic json) {
    _timestamp = json['timestamp'];
    _ip = json['ip'];
    _ipInfo = json['ipInfo'];
    _requestmethod = json['request-method'];
    _scheme = json['scheme'];
    _servername = json['server-name'];
    _serverport = json['server-port'];
    _iptag = json['ip-tag'];
  }

  String? _timestamp;
  String? _ip;
  String? _ipInfo;
  String? _requestmethod;
  String? _scheme;
  String? _servername;
  num? _serverport;
  dynamic _iptag;

  Logs copyWith({
    String? timestamp,
    String? ip,
    String? ipInfo,
    String? requestmethod,
    String? scheme,
    String? servername,
    num? serverport,
    dynamic iptag,
  }) =>
      Logs(
        timestamp: timestamp ?? _timestamp,
        ip: ip ?? _ip,
        ipInfo: ipInfo ?? _ipInfo,
        requestmethod: requestmethod ?? _requestmethod,
        scheme: scheme ?? _scheme,
        servername: servername ?? _servername,
        serverport: serverport ?? _serverport,
        iptag: iptag ?? _iptag,
      );

  String? get timestamp => _timestamp;

  String? get ip => _ip;

  String? get ipInfo => _ipInfo;

  String? get requestmethod => _requestmethod;

  String? get scheme => _scheme;

  String? get servername => _servername;

  num? get serverport => _serverport;

  dynamic get iptag => _iptag;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['timestamp'] = _timestamp;
    map['ip'] = _ip;
    map['ipInfo'] = _ipInfo;
    map['request-method'] = _requestmethod;
    map['scheme'] = _scheme;
    map['server-name'] = _servername;
    map['server-port'] = _serverport;
    map['ip-tag'] = _iptag;
    return map;
  }

  @override
  String toString() {
    return 'Logs{_timestamp: $_timestamp, _ip: $_ip, _ipInfo: $_ipInfo, _requestmethod: $_requestmethod, _scheme: $_scheme, _servername: $_servername, _serverport: $_serverport, _iptag: $_iptag}';
  }
}
