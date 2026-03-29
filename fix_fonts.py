import glob, re, pathlib
root = '.'
files = glob.glob(root + '/**/*.dart', recursive=True)
for f in files:
    p = pathlib.Path(f)
    text = p.read_text(encoding='utf-8')
    new = text
    new = re.sub(r'GoogleFonts\.poppins\s*\(', "TextStyle(fontFamily: 'system-ui', ", new)
    new = re.sub(r'GoogleFonts\.inter\s*\(', "TextStyle(fontFamily: 'system-ui', ", new)
    new = re.sub(r"import\s+'package:google_fonts/google_fonts.dart';\s*\n", '', new)
    if new != text:
        p.write_text(new, encoding='utf-8')
        print('updated', p)
print('done')
