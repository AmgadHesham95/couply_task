import 'package:couply_task/widgets/custom_icon.dart';
import 'package:flutter/material.dart';
import 'package:flick_video_player/flick_video_player.dart';
import 'package:video_player/video_player.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final FlickManager _flickManager;
  late ChatUser _user;
  final _chatTextController = TextEditingController();
  final List<ChatMessage> _messages = [];

  void _initVideoPlayer() {
    _flickManager = FlickManager(
      autoPlay: false,
      videoPlayerController: VideoPlayerController.network(
          'http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4'),
    );
  }

  void _initChatUser() {
    _user = ChatUser(
      id: '1',
      firstName: 'Amgad',
      lastName: 'Hesham',
      profileImage:
          'https://www.upwork.com/profile-portraits/c1t0VFvqmN44E56NLVxtDvxJoFMHcqAr7KMOr9LpYoBAvl_b8YsUGe4VL3p2ODUjj0',
    );
  }

  @override
  void initState() {
    super.initState();
    _initVideoPlayer();
    _initChatUser();
  }

  @override
  void dispose() {
    _flickManager.dispose();
    _chatTextController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_chatTextController.text.isNotEmpty) {
      setState(() {
        _messages.insert(
            0,
            ChatMessage(
                user: _user,
                createdAt: DateTime.now(),
                text: _chatTextController.text));
        _chatTextController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                FlickVideoPlayer(
                  flickManager: _flickManager,
                ),
                Positioned(
                  top: 56,
                  left: 16,
                  right: 16,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        CustomIcon(
                          onTap: () {},
                          color: Colors.blueGrey[900],
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                          ),
                        ),
                        CustomIcon(
                          onTap: () {},
                          color: Colors.blueGrey[900],
                          child: const Icon(
                            Icons.share_outlined,
                            color: Colors.white,
                          ),
                        ),
                      ]),
                ),
              ],
            ),
          ),
          Expanded(
            child: DashChat(
              currentUser: _user,
              onSend: (_) {},
              messages: _messages,
              messageOptions: MessageOptions(
                messageRowBuilder: (message, previousMessage, nextMessage,
                    isAfterDateSeparator, isBeforeDateSeparator) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Stack(
                              alignment: Alignment.bottomRight,
                              fit: StackFit.passthrough,
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundImage:
                                      NetworkImage(_user.profileImage!),
                                ),
                                Transform.translate(
                                  offset: const Offset(5, 5),
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    alignment: Alignment.center,
                                    decoration: const BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: Text(
                                'by',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 2),
                              child: Text(
                                '${_user.firstName!} ${_user.lastName!}',
                                style: TextStyle(
                                  color: Colors.pink[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                              top: 16, right: 32, bottom: 24),
                          child: Text(
                            message.text,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                            ),
                          ),
                        )
                      ],
                    ),
                  );
                },
              ),
              messageListOptions: MessageListOptions(
                showDateSeparator: false,
                chatFooterBuilder: Transform.translate(
                  offset: const Offset(16, 24),
                  child: Row(
                    children: const <Widget>[
                      Icon(
                        Icons.lock_outline_sharp,
                        color: Colors.grey,
                        size: 20,
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Text(
                          'Messages are only seen by you and your partner.',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              inputOptions: InputOptions(
                textController: _chatTextController,
                alwaysShowSend: true,
                sendOnEnter: true,
                inputToolbarMargin: const EdgeInsets.only(top: 0),
                inputToolbarPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                inputDecoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'Share your thoughts with {partner}',
                  hintStyle: const TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(
                      color: Colors.grey,
                      width: 0.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(
                      color: Colors.grey,
                      width: 0.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(
                      color: Colors.grey,
                      width: 0.5,
                    ),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(
                      color: Colors.grey,
                      width: 0.5,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(
                      color: Colors.red,
                      width: 0.5,
                    ),
                  ),
                ),
                sendButtonBuilder: (_) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: CustomIcon(
                      onTap: _sendMessage,
                      color: Colors.pink[700],
                      child: SvgPicture.asset(
                        'assets/images/send.svg',
                      ),
                    ),
                  );
                },
                cursorStyle: CursorStyle(color: Colors.pink[700]),
                inputToolbarStyle: BoxDecoration(
                  color: Colors.grey[300],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
