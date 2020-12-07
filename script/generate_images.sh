#!/bin/bash

PROJECT_PATH=$(git rev-parse --show-toplevel)

CARD_DIR="$PROJECT_PATH/app/public/images/cards"
EMPTY="$CARD_DIR/empty.png"
FONT="$PROJECT_PATH/script/JetBrainsMono-Bold.ttf"
SYMBOLFONT="$PROJECT_PATH/app/assets/vendor/font-awesome/fonts/fontawesome-webfont.ttf"

convert "$EMPTY" -fill black \
  -draw "roundrectangle 10,10 245,370 10,10" \
  -fill red \
  -stroke white \
  -strokewidth 12 \
  -draw "translate 127,190 skewX -20 ellipse 0,0 105,140 0,360" \
  -fill white \
  -stroke black \
  -strokewidth 2 \
  -gravity Center \
  -font "$FONT" \
  -pointsize 100 \
  -draw "rotate -20 text 0,0 NUO" \
  "$CARD_DIR/back.png"

for color in red blue green yellow; do
    c=${color:0:1}
    for number in $(seq 0 9); do
        convert "$EMPTY" -fill $color \
            -draw "roundrectangle 10,10 245,370 10,10" \
            -fill white \
            -stroke white \
            -strokewidth 12 \
            -draw "translate 127,190 skewX -20 ellipse 0,0 105,140 0,360" \
            -fill $color \
            -stroke black \
            -strokewidth 2 \
            -gravity Center \
            -font "$FONT" \
            -pointsize 175 \
            -draw "text 0,0 '$number'" \
            "$CARD_DIR/${c}$number.png"
    done
            convert "$EMPTY" -fill $color \
            -draw "roundrectangle 10,10 245,370 10,10" \
            -fill white \
            -stroke white \
            -strokewidth 12 \
            -draw "translate 127,190 skewX -20 ellipse 0,0 105,140 0,360" \
            -fill $color \
            -stroke black \
            -strokewidth 2 \
            -gravity Center \
            -font "$SYMBOLFONT" \
            -pointsize 175 \
            -draw "text 0,0 ''" \
            "$CARD_DIR/${c}s.png"
            
                        convert "$EMPTY" -fill $color \
            -draw "roundrectangle 10,10 245,370 10,10" \
            -fill white \
            -stroke white \
            -strokewidth 12 \
            -draw "translate 127,190 skewX -20 ellipse 0,0 105,140 0,360" \
            -fill $color \
            -stroke black \
            -strokewidth 2 \
            -gravity Center \
            -font "$SYMBOLFONT" \
            -pointsize 175 \
            -draw "text 0,0 ''" \
            "$CARD_DIR/${c}r.png"

                                    convert "$EMPTY" -fill $color \
            -draw "roundrectangle 10,10 245,370 10,10" \
            -fill white \
            -stroke white \
            -strokewidth 12 \
            -draw "translate 127,190 skewX -20 ellipse 0,0 105,140 0,360" \
            -fill $color \
            -stroke black \
            -strokewidth 2 \
            -gravity Center \
            -font "$FONT" \
            -pointsize 130 \
            -draw "text 0,0 '+2'" \
            "$CARD_DIR/${c}d.png"

    convert "$EMPTY" -fill black \
  -draw "roundrectangle 10,10 245,370 10,10" \
  -stroke white \
  -strokewidth 12 \
  -fill red \
  -draw "path 'M 127,190 L 127,63 A 105,140 0 0,1 239,190'" \
  -fill blue \
  -draw "path 'M 127,190 L 239,190 A 105,140 0 0,1 127,364'" \
  -fill green \
  -draw "path 'M 127,190 L 127,364 A 105,140 0 0,1 16,190'" \
  -fill yellow \
  -draw "path 'M 127,190 L 16,190 A 105,140 0 0,1 127,63'" \
  -fill white \
  -stroke black \
  -strokewidth 2 \
  -gravity Center \
  -font "$FONT" \
  -pointsize 80 \
  -draw "text 0,0 Wild" \
  "$CARD_DIR/xw.png"

      convert "$EMPTY" -fill black \
  -draw "roundrectangle 10,10 245,370 10,10" \
  -stroke white \
  -strokewidth 12 \
  -fill red \
  -draw "path 'M 127,190 L 127,63 A 105,140 0 0,1 239,190'" \
  -fill blue \
  -draw "path 'M 127,190 L 239,190 A 105,140 0 0,1 127,364'" \
  -fill green \
  -draw "path 'M 127,190 L 127,364 A 105,140 0 0,1 16,190'" \
  -fill yellow \
  -draw "path 'M 127,190 L 16,190 A 105,140 0 0,1 127,63'" \
  -fill white \
  -stroke black \
  -strokewidth 2 \
  -gravity Center \
  -font "$FONT" \
  -pointsize 130 \
  -draw "text 0,0 '+4'" \
  "$CARD_DIR/x4.png"
done