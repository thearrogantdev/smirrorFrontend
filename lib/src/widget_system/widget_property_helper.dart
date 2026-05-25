import 'package:smirror_wire/generated/view_view_structure_generated.dart' as bfmsg;

String? propString(List<bfmsg.WidgetProperty>? props, int keyId) {
  if (props == null) return null;
  for (final p in props) {
    if (p.keyId == keyId) {
      final v = p.value;
      if (v is bfmsg.StringValue) return v.value;
      return null; // wrong type for this key
    }
  }
  return null;
}

int? propInt(List<bfmsg.WidgetProperty>? props, int keyId) {
  if (props == null) return null;
  for (final p in props) {
    if (p.keyId == keyId) {
      final v = p.value;
      if (v is bfmsg.IntValue) return v.value;
      return null;
    }
  }
  return null;
}

double? propFloat(List<bfmsg.WidgetProperty>? props, int keyId) {
  if (props == null) return null;
  for (final p in props) {
    if (p.keyId == keyId) {
      final v = p.value;
      if (v is bfmsg.FloatValue) return v.value;
      // Some schemas may encode floats as int when the value is whole:
      if (v is bfmsg.IntValue) return v.value.toDouble();
      return null;
    }
  }
  return null;
}

bool? propBool(List<bfmsg.WidgetProperty>? props, int keyId) {
  if (props == null) return null;
  for (final p in props) {
    if (p.keyId == keyId) {
      final v = p.value;
      if (v is bfmsg.BoolValue) return v.value;
      return null;
    }
  }
  return null;
}

List<int>? propRawBytes(List<bfmsg.WidgetProperty>? props, int keyId) {
  if (props == null) return null;
  for (final p in props) {
    if (p.keyId == keyId) {
      final v = p.value;
      if (v is bfmsg.RawBytes) return v.data;
      return null; // wrong type for this key
    }
  }
  return null;
}
