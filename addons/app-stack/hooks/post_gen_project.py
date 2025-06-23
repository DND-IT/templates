import os
import logging
from jinja2 import Environment, FileSystemLoader

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

environments = @{{ cookiecutter.environments }}

# TODO: This hook should actually call the terraform-backend cookiecutter
# from cookiecutter.main import cookiecutter
# cookiecutter('terraform-backend', no_input=True, output_dir=os.getcwd(), extra_context=environments)})

# Full path to generated project
template_dir = os.getcwd()

env = Environment(loader=FileSystemLoader(template_dir),
                  variable_start_string='<<', variable_end_string='>>'
                  )

templates = [
    "s3.tfbackend.j2",
    "tfvars.j2",
]

for template_name in env.list_templates():
    if os.path.basename(template_name) not in templates:
        continue
    template_path = os.path.join(template_dir, template_name)
    template = env.get_template(template_name)

    template_basename = os.path.basename(template_name)


    for environment_name, environment_data in environments.items():


        rendered_content = template.render(
            environment=environment_name,
            cookiecutter=environment_data
        )

        output_filename = f"{environment_name}.{template_basename}".rstrip(".j2")
        output_file_path = os.path.join(template_dir, os.path.dirname(template_name), output_filename)

        with open(output_file_path, "w") as f:
            f.write(rendered_content)

        print(f"Generated backend file: {os.path.dirname(template_name)}/{output_filename}")

    placeholder_template_path = os.path.join(template_dir, template_name)
    os.remove(placeholder_template_path)
