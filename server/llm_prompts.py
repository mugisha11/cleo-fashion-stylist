"""
LLM prompt templates for Cleo Fashion VTON system
Used for style profiling and outfit explanations
"""

STYLE_PROFILE_PROMPT = """
You are a fashion AI expert analyzing user style preferences from a quiz.

The user has answered 10 fashion image questions with likes/dislikes.
For each liked image, extract and analyze:
- Color preferences (dominant colors, color combinations)
- Silhouette preferences (fitted, loose, structured, flowy)
- Pattern preferences (solid, stripes, prints, abstract)
- Style risk level (conservative 0.0 to bold 1.0)
- Occasion preferences (casual, formal, party, etc.)

Liked Images Data:
{liked_images_data}

Disliked Images Data:
{disliked_images_data}

Return a JSON object with this structure:
{{
    "preferred_colors": ["color1", "color2", ...],
    "preferred_silhouettes": ["silhouette1", "silhouette2", ...],
    "preferred_patterns": ["pattern1", "pattern2", ...],
    "risk_level": 0.0-1.0,
    "style_keywords": ["keyword1", "keyword2", ...],
    "occasion_preferences": ["occasion1", "occasion2", ...]
}}

Be specific and accurate. Base analysis only on the provided image data.
"""

OUTFIT_EXPLANATION_PROMPT = """
You are a fashion stylist explaining a virtual try-on result to the user.

User Style Profile:
{style_profile}

Try-On Result:
- Outfit: {outfit_description}
- User photo: {user_description}

Provide a brief, friendly explanation (2-3 sentences) in {language} explaining:
1. How this outfit matches their style preferences
2. What makes it a good fit
3. Any styling tips

Keep it positive, specific, and actionable.
"""

OUTFIT_EXPLANATION_PROMPT_KINYARWANDA = """
Uri umuhanzi w'imyambaro ukoresha AI wongeraho gusobanura ibyerekeye imyambaro.

Imyitegure y'umukoresha:
{style_profile}

Igisubizo cyo gukoresha:
- Imyambaro: {outfit_description}
- Ifoto y'umukoresha: {user_description}

Tanga isobanuro rito, rwihuse (imvugo 2-3) mu {language} risobanura:
1. Uburyo iyi myambaro ihuje n'imyitegure yabo
2. Icyakora kiyihagije
3. Amahugurwa y'imyambaro

Komeza kuba mwiza, wihariye, kandi ukora.
"""

def get_style_profile_prompt(liked_images: list, disliked_images: list) -> str:
    """Generate style profile prompt"""
    liked_data = "\n".join([
        f"- Image {i+1}: {img.get('tags', [])} | Occasion: {img.get('occasion', 'N/A')}"
        for i, img in enumerate(liked_images)
    ])
    
    disliked_data = "\n".join([
        f"- Image {i+1}: {img.get('tags', [])} | Occasion: {img.get('occasion', 'N/A')}"
        for i, img in enumerate(disliked_images)
    ])
    
    return STYLE_PROFILE_PROMPT.format(
        liked_images_data=liked_data,
        disliked_images_data=disliked_data,
    )

def get_outfit_explanation_prompt(
    style_profile: dict,
    outfit_description: str,
    user_description: str,
    language: str = "English",
) -> str:
    """Generate outfit explanation prompt"""
    template = OUTFIT_EXPLANATION_PROMPT_KINYARWANDA if language == "Kinyarwanda" else OUTFIT_EXPLANATION_PROMPT
    
    return template.format(
        style_profile=str(style_profile),
        outfit_description=outfit_description,
        user_description=user_description,
        language=language,
    )

