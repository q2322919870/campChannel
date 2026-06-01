import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/network/api_client.dart';

class DeviceManagementPage extends StatefulWidget {
  const DeviceManagementPage({super.key});

  @override
  State<DeviceManagementPage> createState() => _DeviceManagementPageState();
}

class _DeviceManagementPageState extends State<DeviceManagementPage> {
  final _apiClient = ApiClient();
  List<Map<String, dynamic>> _devices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDevices();
  }

  Future<void> _fetchDevices() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiClient.get('/users/devices');
      final result = response.data;
      if (result != null && result['code'] == 200 && result['data'] != null) {
        final list = result['data'] as List;
        if (mounted) {
          setState(() {
            _devices = list.map((e) => e as Map<String, dynamic>).toList();
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _kickDevice(String deviceId) async {
    try {
      await _apiClient.post('/users/devices/$deviceId/logout');
      await _fetchDevices();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('设备已下线'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.response?.data?['message'] ?? '操作失败'),
            backgroundColor: Theme.of(context).colorScheme.error,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('设备管理')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchDevices,
              child: _devices.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.6,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.devices, size: 64, color: colorScheme.onSurface.withOpacity(0.2)),
                                const SizedBox(height: 16),
                                Text('暂无设备信息', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.4))),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _devices.length,
                      itemBuilder: (context, index) {
                        final device = _devices[index];
                        final deviceName = device['name']?.toString() ?? device['deviceName']?.toString() ?? '未知设备';
                        final ip = device['ip']?.toString() ?? '';
                        final time = device['time']?.toString() ?? device['lastActive']?.toString() ?? '';
                        final isActive = device['active'] == true || device['current'] == true;
                        final deviceId = device['id']?.toString() ?? '';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: colorScheme.onSurface.withOpacity(0.05)),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? colorScheme.primary.withOpacity(0.15)
                                    : colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                deviceName.toLowerCase().contains('android')
                                    ? Icons.android
                                    : deviceName.toLowerCase().contains('ios') || deviceName.toLowerCase().contains('iphone')
                                        ? Icons.phone_iphone
                                        : Icons.devices,
                                color: isActive ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.4),
                              ),
                            ),
                            title: Text(deviceName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (ip.isNotEmpty)
                                  Text(ip, style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withOpacity(0.5))),
                                if (time.isNotEmpty)
                                  Text(time, style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withOpacity(0.5))),
                              ],
                            ),
                            trailing: isActive && deviceId.isNotEmpty
                                ? TextButton(
                                    onPressed: () => _kickDevice(deviceId),
                                    child: const Text('下线', style: TextStyle(fontSize: 12)),
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
