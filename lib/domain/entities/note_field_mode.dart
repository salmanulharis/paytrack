enum NoteFieldMode {
  mandatory,
  optional,
  disabled;

  String get label => switch (this) {
        NoteFieldMode.mandatory => 'Mandatory',
        NoteFieldMode.optional => 'Optional',
        NoteFieldMode.disabled => 'Disabled',
      };

  static NoteFieldMode fromString(String? value) {
    return NoteFieldMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NoteFieldMode.optional,
    );
  }
}
