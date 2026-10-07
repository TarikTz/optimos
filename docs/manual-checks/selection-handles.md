# Selection and annotation handles — manual checks

1. [ ] Select an area. Eight small white squares appear on the selection border (corners and edges), with any tool active.
2. [ ] Drag a corner and then an edge: the selection resizes, the dim area and size label follow, and the toolbar moves with it (flipping above or inside as needed at the screen edge). It cannot be made smaller than 4 points or flipped inside out, and stays on the screen.
3. [ ] With the Select tool (`V`), drag in empty space inside the selection: the whole selection moves and stays on the screen. A plain click there only deselects any annotation.
4. [ ] Draw a rectangle, an arrow and a pixelate area. With Select, click each: handles appear (eight on a rectangle or pixelate area, one at each end of an arrow). Drag them: the shape resizes within the selection, and a whole drag is one `⌘Z` step.
5. [ ] Text shows no handles and only moves.
6. [ ] Resize the selection, then Copy or Save: the image is exactly the new area, with annotations in the right places (annotations outside it are cut off, those inside are kept).
7. [ ] With a drawing tool (R, A, P, T) active, starting a drag well inside the selection still draws; starting exactly on a selection handle resizes the selection instead.
8. [ ] With no annotations, pressing outside the selection still starts a new selection; with annotations it does nothing. Esc, right-click, Cmd-Tab and Enter, `⌘C`, `⌘S` behave as before.
