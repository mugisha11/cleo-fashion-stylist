/// Example usage of OpenAI Service
/// This file demonstrates how to use the OpenAI service in your Flutter app

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'openai_service.dart';

/// Example: Using OpenAI in a widget
class OpenAIExampleWidget extends ConsumerWidget {
  const OpenAIExampleWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final openAIServiceAsync = ref.watch(openAIServiceProvider);

    return openAIServiceAsync.when(
      data: (service) => _buildContent(context, ref, service),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error: $error'),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, OpenAIService service) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () async {
            try {
              // Example 1: Generate simple text
              final response = await service.generateText(
                prompt: 'What are the latest fashion trends?',
              );
              print('Response: $response');
            } catch (e) {
              print('Error: $e');
            }
          },
          child: const Text('Generate Text'),
        ),
        
        ElevatedButton(
          onPressed: () async {
            try {
              // Example 2: Get fashion advice
              final advice = await service.generateFashionAdvice(
                context: 'I have a casual wardrobe with jeans and t-shirts',
                question: 'What should I wear for a first date?',
              );
              print('Advice: $advice');
            } catch (e) {
              print('Error: $e');
            }
          },
          child: const Text('Get Fashion Advice'),
        ),
        
        ElevatedButton(
          onPressed: () async {
            try {
              // Example 3: Analyze outfit
              final analysis = await service.analyzeOutfit(
                clothingItems: ['black dress', 'red heels', 'pearl necklace'],
                occasion: 'formal dinner',
              );
              print('Analysis: $analysis');
            } catch (e) {
              print('Error: $e');
            }
          },
          child: const Text('Analyze Outfit'),
        ),
      ],
    );
  }
}

/// Example: Using OpenAI in a provider/state management
final fashionAdviceProvider = FutureProvider.family<String, String>((ref, question) async {
  final service = await ref.watch(openAIServiceProvider.future);
  
  return await service.generateFashionAdvice(
    context: 'User wardrobe context here',
    question: question,
  );
});
