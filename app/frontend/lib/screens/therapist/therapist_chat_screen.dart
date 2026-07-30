import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class TherapistChatScreen extends StatefulWidget {
  final String parentName;
  final String studentName;
  final String parentAvatar;

  const TherapistChatScreen({
    super.key,
    required this.parentName,
    required this.studentName,
    required this.parentAvatar,
  });

  @override
  State<TherapistChatScreen> createState() => _TherapistChatScreenState();
}

class _TherapistChatScreenState extends State<TherapistChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  
  // Mock messages
  final List<Map<String, dynamic>> _messages = [
    {
      'text': 'Hi Doctor, I wanted to ask about Kavitha\'s progress this week. She seems more confident with reading at home!',
      'isMe': false,
      'time': '9:15 AM',
      'date': 'Today',
    },
    {
      'text': 'That\'s wonderful to hear! Yes, Kavitha has been making excellent progress with her phonological awareness exercises. Her decoding speed improved by 15% this week.',
      'isMe': true,
      'time': '9:22 AM',
      'date': 'Today',
    },
    {
      'text': 'That\'s great news! Is there anything specific we should practice at home?',
      'isMe': false,
      'time': '9:25 AM',
      'date': 'Today',
    },
    {
      'text': 'I\'d recommend 15 minutes daily of the "syllable segmentation" game in the app. Also, try reading together for 10 minutes before bedtime — let her follow along with her finger.',
      'isMe': true,
      'time': '9:30 AM',
      'date': 'Today',
    },
    {
      'text': 'She still struggles with the letter "b" and "d" confusion. Any tips?',
      'isMe': false,
      'time': '9:34 AM',
      'date': 'Today',
    },
    {
      'text': 'That b/d reversal is very common with dyslexia! Try the "bed" trick — make fists with both hands, thumbs up. Left hand makes a "b", right hand makes a "d". She can check her letters against her hands anytime.',
      'isMe': true,
      'time': '9:38 AM',
      'date': 'Today',
    },
    {
      'text': 'Oh that\'s such a clever trick! I\'ll try that with her tonight. Thank you so much doctor!',
      'isMe': false,
      'time': '9:40 AM',
      'date': 'Today',
    },
  ];

  // Quick reply templates
  final List<String> _quickReplies = [
    'Session went great today! 🎉',
    'Please practice the exercises at home.',
    'Let\'s schedule a follow-up session.',
    'Great improvement this week!',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add({
        'text': text.trim(),
        'isMe': true,
        'time': 'Just now',
        'date': 'Today',
      });
    });
    _messageController.clear();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cardSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.slateBg,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  widget.parentAvatar,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.parentName,
                  style: AppTypography.body(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'parent of ${widget.studentName}',
                  style: AppTypography.caption(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.borderLight),
        ),
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isMe = msg['isMe'] as bool;

                // Show date separator
                bool showDate = index == 0 ||
                    _messages[index - 1]['date'] != msg['date'];

                return Column(
                  children: [
                    if (showDate) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.slateBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            msg['date'],
                            style: AppTypography.caption(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                    Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isMe ? AppColors.calmBlue : AppColors.cardSurface,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(18),
                            topRight: const Radius.circular(18),
                            bottomLeft: Radius.circular(isMe ? 18 : 4),
                            bottomRight: Radius.circular(isMe ? 4 : 18),
                          ),
                          border: isMe ? null : Border.all(color: AppColors.borderLight),
                          boxShadow: [
                            BoxShadow(
                              color: (isMe ? AppColors.calmBlueDark : AppColors.shadow).withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              msg['text'],
                              style: AppTypography.body(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isMe ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              msg['time'],
                              style: TextStyle(
                                fontSize: 11,
                                color: isMe
                                    ? Colors.white.withValues(alpha: 0.7)
                                    : AppColors.textHint,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Quick Replies
          Container(
            height: 44,
            padding: const EdgeInsets.only(left: 12),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _quickReplies.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => _sendMessage(_quickReplies[index]),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.slateBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.borderBlue),
                      ),
                      child: Center(
                        child: Text(
                          _quickReplies[index],
                          style: AppTypography.caption(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.calmBlue,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Input Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              border: Border(top: BorderSide(color: AppColors.borderLight)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.warmWhite,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: TextField(
                        controller: _messageController,
                        style: AppTypography.body(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'type a message...',
                          hintStyle: AppTypography.body(fontSize: 14, color: AppColors.textHint),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onSubmitted: _sendMessage,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _sendMessage(_messageController.text),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: AppColors.blueButtonGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.calmBlueDark.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
