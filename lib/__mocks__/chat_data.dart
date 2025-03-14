class ChatItem {
  final String title;
  final String time;

  const ChatItem({required this.title, required this.time});
}

class ChatSection {
  final String title;
  final List<ChatItem> items;

  const ChatSection({required this.title, required this.items});
}

final List<ChatSection> chatHistory = [
  ChatSection(
    title: 'Today',
    items: [
      ChatItem(
        title: 'Vitamin and Hormone: Key Concept...',
        time: '21 giờ trước',
      ),
    ],
  ),
  ChatSection(
    title: 'Yesterday',
    items: [ChatItem(title: 'Pressure from the Cosmos', time: 'Hôm qua')],
  ),
  ChatSection(
    title: 'This week',
    items: [
      ChatItem(
        title: 'Balancing Omega-3 and Omega-6 for Hear...',
        time: 'Hôm kia',
      ),
      ChatItem(
        title: 'Inulin: A Prebiotic Fiber for Gut Health',
        time: '3 ngày trước',
      ),
      ChatItem(
        title: 'Does Romanian Deadlift Work the Lower ...',
        time: '3 ngày trước',
      ),
      ChatItem(
        title: 'Introverts vs. Extroverts: Differences in ...',
        time: '3 ngày trước',
      ),
      ChatItem(title: 'Tips for Safely Interacting w...', time: '3 ngày trước'),
      ChatItem(
        title: 'Eating Bland Foods for Better Health',
        time: '4 ngày trước',
      ),
    ],
  ),
];
