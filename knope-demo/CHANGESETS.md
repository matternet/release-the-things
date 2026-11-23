How to write a change file for knope-demo (files go in knope-demo/.changeset/, one Markdown file per change):

    ---
    knope-demo: minor
    ---

    # Add return-to-home button

    Any Markdown you like: why, how it was tested, links.

Bump is `major`, `minor` or `patch`. Create one with `knope document-change`
(run inside knope-demo/) or write the file by hand.

Keep only change files in .changeset/: knope reads every .md file there and expects the front-matter header.
