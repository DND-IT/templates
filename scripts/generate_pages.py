import os

def create_markdown_files(base_dirs):
    output_dir = "docs/templates_"
    os.makedirs(output_dir, exist_ok=True)

    for base_dir in base_dirs:
        if not os.path.exists(base_dir):
            print(f"Warning: Directory {base_dir} does not exist")
            continue

        for dir_ in os.listdir(base_dir):
            dir_path = os.path.join(base_dir, dir_)

            if not os.path.isdir(dir_path):
                continue

            readme_path = os.path.join(dir_path, "README.md")

            if os.path.exists(readme_path):
                relative_path = os.path.join("..", "..", "..", base_dir, dir_, "README.md")
                relative_path = relative_path.replace(os.sep, '/')

                markdown_content = '''
{{% include "{relative_path}" %}}

{{% include "template/usage.md" %}}

'''.format(relative_path=relative_path)

                markdown_file_path = os.path.join(output_dir, base_dir, f"{dir_}.md")
                if os.path.exists(markdown_file_path):
                    print(f"File {markdown_file_path} already exists, skipping.")
                    continue
                try:
                    with open(markdown_file_path, 'w') as f:
                        f.write(markdown_content)
                    print(f"Created {markdown_file_path}")
                except IOError as e:
                    print(f"Error writing to {markdown_file_path}: {e}")

def main():
    base_dirs = ["addons", "bases"]
    create_markdown_files(base_dirs)

if __name__ == "__main__":
    main()
