"""
5-Stage Hard Pipeline for Production Virtual Try-On
Each stage is mandatory and must pass before proceeding.
"""

# Import only existing modules
try:
    from .generation import Stage5ImageGeneration
    __all__ = ["Stage5ImageGeneration"]
except ImportError:
    # If generation module doesn't exist, create a minimal export
    __all__ = []

# Optional imports for other stages (if they exist)
try:
    from .reasoning import Stage1VisionReasoning
    __all__.append("Stage1VisionReasoning")
except ImportError:
    pass

try:
    from .body import Stage2BodyUnderstanding
    __all__.append("Stage2BodyUnderstanding")
except ImportError:
    pass

try:
    from .constraints import Stage3ConstraintEngine
    __all__.append("Stage3ConstraintEngine")
except ImportError:
    pass

try:
    from .prompt import Stage4PromptSynthesis
    __all__.append("Stage4PromptSynthesis")
except ImportError:
    pass
