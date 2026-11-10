# Source check: Stigler (1945), Table B (p. 307) and Table 2 (p. 311)

All comparisons below were made by reading rendered page images of the scanned
article (not the PDF text layer). The PDF and the page images are not committed.

## Source file

- URL: https://www.mpi-inf.mpg.de/fileadmin/inf/d1/teaching/winter18/Ideen/Materialien/Stigler-CostofSubsistence.pdf
- Download: HTTP 200, 366018 bytes
- sha256: `b3bac3987491a622be390a5c1e4a8184c3b1262dabd3e67f8a66a12b3c7070da`
- 13 PDF pages (page 1 = JSTOR cover sheet). Page images are 600 dpi bitonal
  JBIG2 scans; the file also carries an OCR text layer.
- Table B: PDF page 6 (1-based), journal page number "307" visible top right
  (running head "THE COST OF SUBSISTENCE"). The page is printed in landscape
  (rotated 90 degrees); its upper part is the end of Table A (rows 51-77), its
  lower part is Table B.
- Table 2: PDF page 10, journal page 311.

## Method

- `pdftoppm` (poppler-utils) to grayscale PNG: page 6 at 400 dpi and 600 dpi,
  page 5 at 600 dpi, page 10 at 300 dpi. Crops/rotation with Pillow.
- Table B was read three times from different renders before the candidate was
  compared: (a) whole table, 600 dpi downsampled by 2; (b) left half / right
  half at native 600 dpi; (c) four column strips at 600 dpi enlarged 2x.
- Third opinion 1: the OCR text layer (`pdftotext -layout`). It is poor
  (e.g. "221.6", "217", "121.2" for 22.6, 27, 12.2) and was not relied on.
- Third opinion 2 (arithmetic): footnote 19 of the article says Table B is
  Table A multiplied by the ratio of 1939 to 1944 prices. For the 11 rows that
  exist in Table A (ids 1, 3, 5, 8, 15, 46, 51, 52, 53, 69, 74) the Table A row
  was read from the 600 dpi images (PDF pages 5 and 6) and
  `TableA_value * price1939 / price1944` was compared with each Table B cell.

## What is printed (Table B)

- Title: "TABLE B. NUTRITIVE VALUES OF COMMON FOODS PER DOLLAR OF EXPENDITURE,
  AUGUST 15, 1944" (small caps).
- Column headers, in printed order: Commodity | Price Aug. 15, 1944 (cents) |
  Calories (1,000) | Protein (grams) | Calcium (grams) | Iron (mg.) |
  Vitamin A (1,000 I.U.) | Thiamine (mg.) | Riboflavin (mg.) | Niacin (mg.) |
  Ascorbic Acid (mg.).
- 14 rows, numbered 1, 3, 5, 8, 15, 46, 51, 52, 53, 69, 74, 78, 79, 80.
  Printed names: Wheat Flour, Wheat Cereal, Corn Meal, Rolled Oats, Evaporated
  Milk, Cabbage, Potatoes, Spinach, Sweet Potatoes, Navy Beans, Sugar,
  Pancake Flour(1), Beets(2), Liver (Pork)(3).
- Footnotes: "1 Unit: 20 oz.; edible weight: 4,647 g." "2 Unit: 1 bunch;
  edible weight: 4,971 g." "3 Unit: 1 lb.; edible weight: 2,071 g."
- **Table B has no Unit column and no Edible Weight column.** Units for ids
  78-80 come from the footnotes above. Units for ids 1-74 are printed only in
  Table A (pp. 306-307): 10 lb., 28 oz., 1 lb., 1 lb., 14 1/2 oz., 1 lb.,
  15 lb., 1 lb., 1 lb., 1 lb., 10 lb. They agree with the candidate
  (candidate "14.5 oz" = printed "14½ oz."). The unit column of
  `tableB_p307_independent.csv` is filled from these two places.
- Empty cells: two kinds are printed. A dash "—" (spinach calcium; sugar
  protein, calcium, iron) and plain white space (all other empty cells, i.e.
  vitamin A for ids 1, 3, 8, 69, 74, 78; ascorbic acid for ids 1, 3, 5, 8, 69,
  74, 78; sugar thiamine, riboflavin, niacin). Both are left empty in the
  independent CSV and flagged `printed_blank=1`. No cell prints a zero.
- Decimal fractions below one are printed without leading zero (".8", ".2").
  Thousands are printed with a comma ("4,054").

## Result of the comparison (14 rows x 10 columns = 140 cells)

- Matching cells: 139 (a candidate 0 against an empty/dash cell is counted as a
  match and flagged `printed_blank=1`; 20 such cells).
- Non-matching / doubtful cells: 1.

| id | column | candidate | image reading | legibility |
|----|--------|-----------|---------------|------------|
| 3 (Wheat Cereal) | protein (g) | 398 | 393 or 398; recorded as 393 | faint (last digit ambiguous) |

Details for that cell: in this typeface/scan the bold "3" is often inked almost
shut and resembles "8". The last digit of this number is such a glyph; it has
the left-hand notch and spur seen on other 3s on the page, but it cannot be
read with certainty from the image. The OCR text layer gives "398". The
arithmetic check gives 393: Table A row 3 reads price 24.2, protein 377, and
377 x 24.2 / 23.2 = 393.2 (392.7-393.8 allowing for rounding of 377), while
every other cell of the row reproduces to the printed digit with the same ratio
(11.8 -> 12.3, 14.4 -> 15.0, 175 -> 183, 14.4 -> 15.0, 8.8 -> 9.2, 114 -> 119).
Conclusion: the printed value is most probably 393, not 398; this is a
judgement from a degraded glyph plus arithmetic, not a clean reading.

Other cells containing the same heavy "3" glyph (e.g. prices 6.3 and 7.3,
calories 26.3, protein 283 and 143, vitamin A 641.3 and 132.3, riboflavin 3.4
and 6.3) were read as in the candidate; for ids 5, 15, 46, 51, 52 they are also
confirmed by the arithmetic check, so they are marked clear.

Arithmetic check summary: for ids 1, 5, 8, 15, 46, 51, 52, 53, 69, 74 every
non-empty Table B cell equals Table A x price ratio to the printed rounding
(at most one unit in the last digit). Table A rows as read (price; calories,
protein, calcium, iron, vitamin A, thiamine, riboflavin, niacin, ascorbic acid):

- 1: 36.0; 44.7, 1,411, 2.0, 365, blank, 55.4, 33.3, 441, blank
- 3: 24.2; 11.8, 377, 14.4, 175, blank, 14.4, 8.8, 114, blank
- 5: 4.6; 36.0, 897, 1.7, 99, 30.9, 17.4, 7.9, 106, blank
- 8: 7.1; 25.3, 907, 5.1, 341, blank, 37.1, 8.9, 64, blank
- 15: 6.7; 8.4, 422, 15.1, 9, 26.0, 3.0, 23.5, 11, 60
- 46: 3.7; 2.6, 125, 4.0, 36, 7.2, 9.0, 4.5, 26, 5,369
- 51: 34.0; 14.3, 336, 1.8, 118, 6.7, 29.4, 7.1, 198, 2,522
- 52: 8.1; 1.1, 106, —, 138, 918.4, 5.7, 13.8, 33, 2,755
- 53: 5.1; 9.6, 138, 2.7, 54, 290.7, 8.4, 5.4, 83, 1,912
- 69: 5.9; 26.9, 1,691, 11.4, 792, blank, 38.4, 24.6, 217, blank
- 74: 51.7; 34.9, —, —, —, blank, blank, blank, blank, blank

## Table 2 (journal page 311, PDF page 10)

Title: "TABLE 2. MINIMUM COST ANNUAL DIETS, AUGUST 1939 AND 1944".
Columns: Commodity | August 1939: Quantity, Cost | August 1944: Quantity, Cost.

| Commodity | 1939 quantity | 1939 cost | 1944 quantity | 1944 cost |
|-----------|---------------|-----------|---------------|-----------|
| Wheat Flour | 370 lb. | $13.33 | 535 lb. | $34.53 |
| Evaporated Milk | 57 cans | 3.84 | — | — |
| Cabbage | 111 lb. | 4.11 | 107 lb. | 5.23 |
| Spinach | 23 lb. | 1.85 | 13 lb. | 1.56 |
| Dried Navy Beans | 285 lb. | 16.80 | — | — |
| Pancake Flour | — | — | 134 lb. | 13.08 |
| Pork Liver | — | — | 25 lb. | 5.48 |
| Total Cost | | $39.93 | | $59.88 |

Read once at 300 dpi; all digits clear. Internal checks: the cost columns sum
exactly to the printed totals (39.93 and 59.88), and quantity x unit price
reproduces each cost within a few cents (e.g. 535 lb. x 6.46 c = 34.56;
134 lb. x 12.2 c per 20 oz. = 13.08; 25 lb. x 21.9 c = 5.48). The OCR text layer
is wrong here ("585 lb.", "$13.83", "5.28") and must not be used.

## Days per year

No sentence in the article states the number of days used for the annual
figures ("365" does not occur in the text; searched in the OCR layer, which is
imperfect). Table 1 is headed "Daily allowances of nutrients ..." and Table 3
reports "Percent of Year's Allowance". The only indirect evidence is the note on
p. 311: "it would require $24.50 to supply for a year the calories from flour
(commodity no. 1). But then only 61 days' calcium would be provided". With
flour at 44.7 thousand calories per dollar (Table A) and the 3,000-calorie
daily allowance of Table 1 (p. 304; taken from the OCR text layer, not re-read from the image),
3 / 44.7 x 365 = $24.50, so 365 days is implied but not stated.

## Limitations

- One reader, one scan. The scan is a bitonal JBIG2 image; JBIG2 encoders can
  substitute similar-looking glyphs, so a scan artefact in 3/8, 5/6 or 1/7
  cannot be excluded from the image alone. This is why the arithmetic check
  against Table A was added.
- Ids 78, 79, 80 are not in Table A, so their 30 cells are verified by image
  reading only (three renders, all agreeing with the candidate).
- The arithmetic check is only as good as my reading of the Table A rows listed
  above, which were read once each.
- Names in the candidate differ from the printed names only in capitalisation
  ("Wheat flour" vs "Wheat Flour"); "Liver (Pork)" is the printed form in
  Table B, "Pork Liver" in Table 2.
