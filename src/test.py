import markdown
from mcgtextension import MCellGridTableExtension

with open("test.md", "r", encoding="utf-8") as input_file:
    text = input_file.read()
html = markdown.markdown(text, extensions=[MCellGridTableExtension()])
print(html)