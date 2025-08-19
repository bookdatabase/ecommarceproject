import 'package:eaglesteelfurniture/screens/ProfileScreen.dart';
import 'package:eaglesteelfurniture/screens/WishlistScreen.dart';
import 'package:eaglesteelfurniture/screens/cartscreen.dart';
import 'package:eaglesteelfurniture/theme/theme%20management.dart';
import 'package:eaglesteelfurniture/widgets/SliderWidget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/product_card.dart';
import '../widgets/category_card.dart';
import '../core/providers/firebase_providers.dart';
import 'category_screen.dart';
import 'product_detail_screen.dart';
import 'search_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final user = FirebaseAuth.instance.currentUser;

    final cartCount = ref.watch(cartProvider); // 👈 Watch cart count

    // Hardcoded slider images
    final List<String> sliderImages = [
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcThr0PnmdP77U7GWF4REfEgiIMiwxogG1p-8W87UGeG21k2X7dUXJowpnFr-C9PoNz387c&usqp=CAU',
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRW_lDBvu4bdFZv-xwMeouDdkE6OHrTT1-MVOalB8vFpDaXn5DriJlSOj1zFGKsGNlt4_M&usqp=CAU',
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSBsWzbzG8m4FtOQpq_GMVZ0gOhmXQ-mqeA2cTqob-Vij51CD339bGpDZldAR5biaCkETI&usqp=CAU',
    ];

    Widget buildHomeContent() {
      return RefreshIndicator(
        onRefresh: () async {
          ref.refresh(productsProvider);
          ref.refresh(categoriesProvider);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SliderWidget(imageUrls: sliderImages),
              const SizedBox(height: 24),
              const Text(
                'Categories',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              categoriesAsync.when(
                data: (categories) => SizedBox(
                  height: 100,
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return SizedBox(
                        width: 110,
                        child: CategoryCard(
                          category: category,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    CategoryScreen(category: category),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Error: $error')),
              ),
              const SizedBox(height: 5),
              const Text(
                'Hot Deals',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              productsAsync.when(
                data: (products) => GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.7,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return ProductCard(
                      product: product,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ProductDetailScreen(product: product),
                          ),
                        );
                      },
                    );
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Error: $error')),
              ),
            ],
          ),
        ),
      );
    }

    final List<Widget> _pages = [
      buildHomeContent(),
      const WishlistScreen(),
      CartScreen(userId: user?.uid ?? ''),
      const ProfileScreen(),
    ];

    AppBar? appBar;
    if (_selectedIndex == 0) {
      appBar = AppBar(
        backgroundColor: Colors.green,
        title: const Text(''),
        leading: Consumer(
          builder: (context, ref, _) {
            final themeMode = ref.watch(themeProvider);
            final themeNotifier = ref.read(themeProvider.notifier);

            return IconButton(
              icon: Icon(
                color: Colors.white,
                themeMode == ThemeMode.light
                    ? Icons.dark_mode
                    : Icons.light_mode,
              ),
              onPressed: () {
                themeNotifier.toggleTheme();
              },
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
          ),
        ],
      );
    }

    return Scaffold(
      appBar: appBar,
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          const BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.shopping_cart, size: 28),
                if (cartCount > 0)
                  Positioned(
                    right: -6,
                    top: -5,
                    child: Container(
                      padding: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$cartCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Cart',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
