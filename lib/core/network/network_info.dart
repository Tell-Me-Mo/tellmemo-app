abstract class NetworkInfo {
  Future<bool> get isConnected;
}

class NetworkInfoImpl implements NetworkInfo {
  @override
  Future<bool> get isConnected async {
    // For web, we'll assume connection is available
    // In a real app, you might want to use connectivity_plus package
    // or implement actual network checking
    return true;
  }
}