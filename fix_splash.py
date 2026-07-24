with open('app/frontend/lib/screens/splash_screen.dart', 'r') as f:
    content = f.read()

import re

# We want to replace the row of letters with "Sipsara"
# The letters are wrapped in a Row -> children -> [ ... ]
# We will match the entire Row block for "AdaptedMind" and replace it.

pattern = r'Row\(\s*mainAxisAlignment: MainAxisAlignment\.center,\s*crossAxisAlignment: CrossAxisAlignment\.center,\s*children: \[\s*_buildLetterElement\(.*?\]\s*,\s*\)'

# Wait, the structure in splash_screen.dart is:
# Row(
#   mainAxisAlignment: MainAxisAlignment.center,
#   crossAxisAlignment: CrossAxisAlignment.center,
#   children: [ ... ]
# )
# It might be easier to replace using string manipulation or a more robust approach.

old_letters = """                    // Top word: "Adapted"
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildLetterElement(
                          text: 'A',
                          delay: 0.0,
                          fromOffset: const Offset(-80, -60),
                          fontSize: letterSize,
                          textColor: _textDark,
                        ),
                        _buildLetterElement(
                          text: 'd',
                          delay: 0.05,
                          fromOffset: const Offset(0, -100),
                          fontSize: letterSize,
                          textColor: _calmBlue,
                        ),
                        _buildLetterElement(
                          text: 'a',
                          delay: 0.10,
                          fromOffset: const Offset(60, -40),
                          fontSize: letterSize,
                          textColor: _textDark,
                        ),
                        _buildLetterElement(
                          text: 'p',
                          delay: 0.15,
                          fromOffset: const Offset(-50, 80),
                          fontSize: letterSize,
                          textColor: _warmAmber,
                        ),
                        _buildLetterElement(
                          text: 't',
                          delay: 0.20,
                          fromOffset: const Offset(100, 20),
                          fontSize: letterSize,
                          textColor: _gentleGreen,
                        ),
                        _buildLetterElement(
                          text: 'e',
                          delay: 0.25,
                          fromOffset: const Offset(20, -80),
                          fontSize: letterSize,
                          textColor: _textDark,
                        ),
                        _buildLetterElement(
                          text: 'd',
                          delay: 0.30,
                          fromOffset: const Offset(-40, -40),
                          fontSize: letterSize,
                          textColor: _calmBlue,
                        ),
                      ],
                    ),
                    // Bottom word: "Mind"
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildLetterElement(
                          text: 'M',
                          delay: 0.40,
                          fromOffset: const Offset(-100, 50),
                          fontSize: letterSize,
                          textColor: _warmAmber,
                        ),
                        _buildLetterElement(
                          text: 'i',
                          delay: 0.45,
                          fromOffset: const Offset(50, -80),
                          fontSize: letterSize,
                          textColor: _gentleGreen,
                        ),
                        _buildLetterElement(
                          text: 'n',
                          delay: 0.50,
                          fromOffset: const Offset(-60, 100),
                          fontSize: letterSize,
                          textColor: _calmBlue,
                        ),
                        _buildLetterElement(
                          text: 'd',
                          delay: 0.55,
                          fromOffset: const Offset(80, 40),
                          fontSize: letterSize,
                          textColor: _textDark,
                        ),
                      ],
                    ),"""

new_letters = """                    // Top word: "Sipsara"
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildLetterElement(
                          text: 'S',
                          delay: 0.0,
                          fromOffset: const Offset(-80, -60),
                          fontSize: letterSize,
                          textColor: _textDark,
                        ),
                        _buildLetterElement(
                          text: 'i',
                          delay: 0.05,
                          fromOffset: const Offset(0, -100),
                          fontSize: letterSize,
                          textColor: _calmBlue,
                        ),
                        _buildLetterElement(
                          text: 'p',
                          delay: 0.10,
                          fromOffset: const Offset(60, -40),
                          fontSize: letterSize,
                          textColor: _textDark,
                        ),
                        _buildLetterElement(
                          text: 's',
                          delay: 0.15,
                          fromOffset: const Offset(-50, 80),
                          fontSize: letterSize,
                          textColor: _warmAmber,
                        ),
                        _buildLetterElement(
                          text: 'a',
                          delay: 0.20,
                          fromOffset: const Offset(100, 20),
                          fontSize: letterSize,
                          textColor: _gentleGreen,
                        ),
                        _buildLetterElement(
                          text: 'r',
                          delay: 0.25,
                          fromOffset: const Offset(20, -80),
                          fontSize: letterSize,
                          textColor: _textDark,
                        ),
                        _buildLetterElement(
                          text: 'a',
                          delay: 0.30,
                          fromOffset: const Offset(-40, -40),
                          fontSize: letterSize,
                          textColor: _calmBlue,
                        ),
                      ],
                    ),"""

content = content.replace(old_letters, new_letters)

with open('app/frontend/lib/screens/splash_screen.dart', 'w') as f:
    f.write(content)
print("Fixed splash_screen.dart")

