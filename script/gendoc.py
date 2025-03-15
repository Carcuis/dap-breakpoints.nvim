import os
import re
from pathlib import Path
from shutil import which


class UserPath:
    project_path: Path = Path(__file__).parents[1].relative_to(Path.cwd())
    path_yaml: Path = project_path / "script" / "path.yaml"
    readme: Path = project_path / "README.md"
    output_vimdoc: Path = project_path / "doc" / "dap-breakpoints.txt"
    panvimdoc: Path = Path("")

    @classmethod
    def read_path_from_yaml(cls) -> None:
        try:
            with open(cls.path_yaml, 'r') as stream:
                content = stream.read()
                panvimdoc_path = re.search(r'^panvimdoc:\s*(\S+)$', content)
                assert panvimdoc_path is not None, "Error: panvimdoc path not found in path.yaml."
                cls.panvimdoc = Path(os.path.expanduser(panvimdoc_path.group(1)))
                assert UserPath.panvimdoc.exists(), f"Error: panvimdoc GitHub repo not found at {UserPath.panvimdoc}."
        except Exception as err:
            print(err)
            exit(1)


class GenerateVimdoc:
    project_name: str = "dap-breakpoints"
    nvim_version: str = "NVIM 0.10"

    @staticmethod
    def check_dependency() -> None:
        if which("pandoc") is None:
            print("Error: pandoc executable not found.")
            exit(1)

    @classmethod
    def run_generate(cls) -> None:
        command = [
            "pandoc",
            "--to=" + str(UserPath.panvimdoc / "scripts" / "panvimdoc.lua"),
            "--lua-filter=" + str(UserPath.panvimdoc / "scripts" / "include-files.lua"),
            "--lua-filter=" + str(UserPath.panvimdoc / "scripts" / "skip-blocks.lua"),
            "--shift-heading-level-by=0",
            "--metadata=project:" + cls.project_name,
            "--metadata=vimversion:\"" + cls.nvim_version + "\"",
            "--metadata=toc:true",
            "--metadata=description:",
            "--metadata=titledatepattern:\"%Y %B %d\"",
            "--metadata=dedupsubheadings:false",
            "--metadata=ignorerawblocks:true",
            "--metadata=docmapping:false",
            "--metadata=docmappingproject:true",
            "--metadata=treesitter:true",
            "--metadata=incrementheadinglevelby=0",
            str(UserPath.readme.absolute()),
            "--output=" + str(UserPath.output_vimdoc.absolute())
        ]

        if os.system(" ".join(command)) == 0:
            print(f"Generated {UserPath.output_vimdoc} from {UserPath.readme}.")
        else:
            print("Error: pandoc command failed.")

    @staticmethod
    def post_modify() -> None:
        with open(UserPath.output_vimdoc, 'r', encoding='utf-8') as file:
            content = file.read()
            content = re.sub(r"^  (\- \w+(?: \w+)?)", r"\1  ", content.replace(
                "Table of Contents                          *dap-breakpoints-table-of-contents*",
                "CONTENTS                                                     *dap-breakpoints*"
            ).replace(
                "1. dap-breakpoints.nvim                 |dap-breakpoints-dap-breakpoints.nvim|",
                "  - Introduction                                |dap-breakpoints-introduction|"
            ).replace(
                "1. dap-breakpoints.nvim                 *dap-breakpoints-dap-breakpoints.nvim*",
                "INTRODUCTION                                    *dap-breakpoints-introduction*"
            ), flags=re.MULTILINE)
        with open(UserPath.output_vimdoc, 'w', encoding='utf-8') as file:
            file.write(content)


if __name__ == "__main__":
    UserPath.read_path_from_yaml()
    GenerateVimdoc.check_dependency()
    GenerateVimdoc.run_generate()
    GenerateVimdoc.post_modify()

