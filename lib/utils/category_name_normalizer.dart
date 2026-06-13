String normalizeCategoryName(String value) {
  const source =
      'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
  const target =
      'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
  var normalized = value.trim().toLowerCase();
  for (var index = 0; index < source.length; index++) {
    normalized = normalized.replaceAll(source[index], target[index]);
  }
  return normalized.replaceAll(RegExp(r'\s+'), ' ');
}
