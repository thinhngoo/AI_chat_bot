import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../services/chat_service.dart';

class AssistantManagementScreen extends StatefulWidget {
  const AssistantManagementScreen({super.key});

  @override
  State<AssistantManagementScreen> createState() => _AssistantManagementScreenState();
}

class _AssistantManagementScreenState extends State<AssistantManagementScreen> {
  final Logger _logger = Logger();
  final ChatService _chatService = ChatService();
  
  bool _isLoading = true;
  String _errorMessage = '';
  List<Map<String, dynamic>> _assistants = [];
  
  @override
  void initState() {
    super.initState();
    _fetchAssistants();
  }
  
  Future<void> _fetchAssistants() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final assistants = await _chatService.getAssistants();
      
      if (mounted) {
        setState(() {
          _assistants = assistants;
          _isLoading = false;
        });
      }
    } catch (e) {
      _logger.e('Error fetching assistants: $e');
      
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _deleteAssistant(String assistantId) async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: const Text('Bạn có chắc chắn muốn xóa trợ lý này không? Hành động này không thể hoàn tác.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      
      if (confirmed == true) {
        // Show loading indicator
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đang xóa trợ lý...'),
              duration: Duration(seconds: 1),
            ),
          );
        }
        
        await _chatService.deleteAssistant(assistantId);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã xóa trợ lý thành công'),
              backgroundColor: Colors.green,
            ),
          );
          
          _fetchAssistants(); // Refresh the list
        }
      }
    } catch (e) {
      _logger.e('Error deleting assistant: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xóa trợ lý: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _createAssistant() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AssistantFormScreen(
          title: 'Tạo trợ lý mới',
          isCreating: true,
        ),
      ),
    ).then((_) => _fetchAssistants());
  }
  
  void _updateAssistant(Map<String, dynamic> assistant) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AssistantFormScreen(
          title: 'Cập nhật trợ lý',
          isCreating: false,
          assistant: assistant,
        ),
      ),
    ).then((_) => _fetchAssistants());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý trợ lý AI'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Lỗi: $_errorMessage',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchAssistants,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : _assistants.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Không có trợ lý nào.'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _createAssistant,
                            child: const Text('Tạo trợ lý mới'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchAssistants,
                      child: ListView.builder(
                        itemCount: _assistants.length,
                        itemBuilder: (context, index) {
                          final assistant = _assistants[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            child: ListTile(
                              title: Text(assistant['name'] ?? 'Không có tên'),
                              subtitle: Text(
                                'Model: ${assistant['model'] ?? 'N/A'}\n${assistant['description'] ?? 'Không có mô tả'}',
                              ),
                              isThreeLine: true,
                              leading: const CircleAvatar(
                                child: Icon(Icons.smart_toy),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _updateAssistant(assistant),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteAssistant(assistant['id']),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createAssistant,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AssistantFormScreen extends StatefulWidget {
  final String title;
  final bool isCreating;
  final Map<String, dynamic>? assistant;

  const AssistantFormScreen({
    super.key,
    required this.title,
    required this.isCreating,
    this.assistant,
  });

  @override
  State<AssistantFormScreen> createState() => _AssistantFormScreenState();
}

class _AssistantFormScreenState extends State<AssistantFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _instructionsController = TextEditingController();
  final ChatService _chatService = ChatService();
  final Logger _logger = Logger();
  
  String _selectedModel = 'gpt-4o-mini';
  bool _isLoading = false;
  
  final List<Map<String, String>> _availableModels = [
    {'id': 'gpt-4o-mini', 'name': 'GPT-4o mini'},
    {'id': 'gpt-4o', 'name': 'GPT-4o'},
    {'id': 'gemini-1.5-flash-latest', 'name': 'Gemini 1.5 Flash'},
    {'id': 'gemini-1.5-pro-latest', 'name': 'Gemini 1.5 Pro'},
    {'id': 'claude-3-haiku-20240307', 'name': 'Claude 3 Haiku'},
    {'id': 'claude-3-sonnet-20240229', 'name': 'Claude 3 Sonnet'},
  ];

  @override
  void initState() {
    super.initState();
    
    if (!widget.isCreating && widget.assistant != null) {
      _nameController.text = widget.assistant!['name'] ?? '';
      _descriptionController.text = widget.assistant!['description'] ?? '';
      _instructionsController.text = widget.assistant!['instructions'] ?? '';
      _selectedModel = widget.assistant!['model'] ?? 'gpt-4o-mini';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }
  
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      if (widget.isCreating) {
        // Create a new assistant
        await _chatService.createAssistant(
          name: _nameController.text,
          model: _selectedModel,
          instructions: _instructionsController.text,
          description: _descriptionController.text,
        );
        
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã tạo trợ lý thành công'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Update an existing assistant
        await _chatService.updateAssistant(
          assistantId: widget.assistant!['id'],
          name: _nameController.text,
          model: _selectedModel,
          instructions: _instructionsController.text,
          description: _descriptionController.text,
        );
        
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật trợ lý thành công'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      if (mounted) {
        Navigator.of(context).pop(); // Return to the previous screen
      }
    } catch (e) {
      _logger.e('Error submitting assistant form: $e');
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên trợ lý',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên trợ lý';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                value: _selectedModel,
                decoration: const InputDecoration(
                  labelText: 'Model',
                  border: OutlineInputBorder(),
                ),
                items: _availableModels.map((model) {
                  return DropdownMenuItem<String>(
                    value: model['id'],
                    child: Text(model['name']!),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedModel = value;
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng chọn model';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Mô tả',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _instructionsController,
                decoration: const InputDecoration(
                  labelText: 'Hướng dẫn',
                  hintText: 'Nhập hướng dẫn cho trợ lý của bạn',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập hướng dẫn cho trợ lý';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(
                        widget.isCreating ? 'Tạo trợ lý' : 'Cập nhật trợ lý',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
