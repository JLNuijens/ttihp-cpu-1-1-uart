"""
Extend the tile Metal4 stripes across the SRAM after the power grid is built.
LibreLane imports librelane_plugin_* from the repo root. The step is inserted
by meta.substituting_steps in src/config.json.
"""
import os

from librelane.steps import Step
from librelane.steps.odb import OdbpyStep
from librelane.config import Variable
from typing import Optional
from decimal import Decimal

HERE = os.path.dirname(os.path.abspath(__file__))


@Step.factory.register()
class ExtendPowerStripes(OdbpyStep):
    id = "Project.ExtendPowerStripes"
    name = "Extend Power Stripes Over SRAM"

    def get_script_path(self):
        return os.path.join(HERE, "odb_stripes.py")

    config_vars = [
        Variable("EXTEND_STRIPES_LAYER", str, "Vertical PDN layer.", default="Metal4"),
        Variable("EXTEND_STRIPES_SRAM_LAYER", Optional[str], "SRAM power layer when it is not the stripe layer.", default=None),
        Variable("EXTEND_STRIPES_CLEARANCE", Decimal, "Spacing from the other net.", units="um", default=Decimal("0.24")),
        Variable("EXTEND_STRIPES_STACK_PITCH", Decimal, "Via stack pitch along a column.", units="um", default=Decimal("10")),
        Variable("EXTEND_STRIPES_PIN_FACE_MARGIN", Decimal, "Keep via stacks off the pin face. 0 leaves the existing stacks.", units="um", default=Decimal("0")),
        Variable("EXTEND_STRIPES_SRAM_ALL_COLUMNS", bool, "Stripe every SRAM supply column.", default=False),
        Variable("EXTEND_STRIPES_SRAM_ARRAY_EVERY_OTHER", bool, "Stripe every other array pair.", default=True),
    ]

    def get_command(self):
        cmd = super().get_command() + [
            "--layer", self.config["EXTEND_STRIPES_LAYER"],
            "--clearance", str(self.config["EXTEND_STRIPES_CLEARANCE"]),
            "--stack-pitch", str(self.config["EXTEND_STRIPES_STACK_PITCH"]),
            "--pin-face-margin", str(self.config["EXTEND_STRIPES_PIN_FACE_MARGIN"]),
        ]
        if self.config.get("EXTEND_STRIPES_SRAM_LAYER"):
            cmd += ["--sram-layer", self.config["EXTEND_STRIPES_SRAM_LAYER"]]
        cmd += ["--sram-all-columns" if self.config["EXTEND_STRIPES_SRAM_ALL_COLUMNS"] else "--sram-grid-columns"]
        if self.config["EXTEND_STRIPES_SRAM_ARRAY_EVERY_OTHER"]:
            cmd += ["--sram-array-every-other"]
        return cmd
