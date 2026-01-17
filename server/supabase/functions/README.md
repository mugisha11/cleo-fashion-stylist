# Supabase Edge Functions

This directory contains Supabase Edge Functions written in Deno/TypeScript.

## Setup

1. Install Supabase CLI: `npm install -g supabase`
2. Login: `supabase login`
3. Link your project: `supabase link --project-ref YOUR_PROJECT_REF`

## Functions

### `chat-completion`
Handles AI chat conversations using OpenAI.

### `fashion-ai-reasoning`
Generates intelligent outfit recommendations with ChatGPT-level reasoning.

### `generate-daily-recommendations`
Background job that runs daily to generate outfit recommendations.

## Development

To test locally:
```bash
supabase functions serve
```

To deploy:
```bash
supabase functions deploy <function-name>
```

## TypeScript/Deno Configuration

Each function has a `deno.json` file for Deno configuration. The `.vscode/settings.json` enables Deno support in VS Code.

If you see TypeScript errors in your IDE:
1. Install the Deno VS Code extension
2. The `deno.json` files configure Deno types
3. The `.vscode/settings.json` enables Deno for these directories

These errors are IDE-only and won't affect runtime execution in Supabase Edge Functions.
