FROM squidfunk/mkdocs-material:latest

# A list of awesome MkDocs projects and plugins : https://github.com/mkdocs/catalog
RUN pip install mkdocs-mermaid2-plugin
# https://github.com/JakubAndrysek/mkdocs-glightbox
RUN pip install mkdocs-glightbox
# https://github.com/lukasgeiter/mkdocs-awesome-pages-plugin
RUN pip install mkdocs-awesome-pages-plugin
# https://github.com/JakubAndrysek/mkdocs-open-in-new-tab
RUN pip install mkdocs-open-in-new-tab