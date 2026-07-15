import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class Employee {
  final String name;
  final String nip;
  final String jabatan;
  final String unit;
  final String image;
  final String status;

  Employee({
    required this.name,
    required this.nip,
    required this.jabatan,
    required this.unit,
    required this.image,
    required this.status,
  });
}

class _HomePageState extends State<HomePage> {

  final Color primaryColor = const Color(0xffB98936);

  final TextEditingController searchController = TextEditingController();

  String selectedFilter = "All";

  final List<String> filters = [
    "All",
    "ASN",
    "Jabatan Struktural",
    "Jabatan Fungsional",
    "P3K",
    "P3K Paruh Waktu",
    "PJLP",
  ];

  final List<Employee> employees = [

    Employee(
      name: "Lionel Messi S.Kom",
      nip: "122342342",
      jabatan: "Kepala Umum",
      unit: "Sub Bagian UI",
      image:
          "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=300",
      status: "Berhasil",
    ),

    Employee(
      name: "Cristiano Ronaldo",
      nip: "202342342",
      jabatan: "Sekretaris",
      unit: "Sub Bagian Kepegawaian",
      image:
          "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=300",
      status: "Berhasil",
    ),

    Employee(
      name: "Kevin De Bruyne",
      nip: "912312312",
      jabatan: "Analis",
      unit: "Sub Bagian Administrasi",
      image:
          "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=300",
      status: "Pending",
    ),

    Employee(
      name: "Erling Haaland",
      nip: "888999111",
      jabatan: "Kepala Bidang",
      unit: "Peternakan",
      image:
          "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=300",
      status: "Perlu Revisi",
    ),
  ];

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xffEFEFEF),

      body: SafeArea(

        child: Container(

          decoration: BoxDecoration(

            gradient: LinearGradient(

              begin: Alignment.topCenter,

              end: Alignment.bottomCenter,

              colors: [

                primaryColor.withOpacity(.95),

                Colors.white,

              ],

            ),

          ),

          child: Column(

            children: [

              const SizedBox(height: 20),

              Padding(

                padding: const EdgeInsets.symmetric(horizontal: 20),

                child: Row(

                  children: [

                    Image.asset(

                      "assets/images/logo/logo.png",

                      width: 50,

                    ),

                    const SizedBox(width: 15),

                    const Expanded(

                      child: Column(

                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [

                          Text(

                            "SIKAP",

                            style: TextStyle(

                              fontSize: 28,

                              color: Colors.white,

                              fontWeight: FontWeight.bold,

                            ),

                          ),

                          SizedBox(height: 2),

                          Text(

                            "Sistem Informasi Kepegawaian dan\nArsip Pegawai",

                            style: TextStyle(

                              color: Colors.white,

                              fontSize: 14,

                            ),

                          ),

                        ],

                      ),

                    ),

                    IconButton(

                      onPressed: () {},

                      icon: const Icon(

                        Icons.notifications,

                        color: Colors.white,

                        size: 28,

                      ),

                    )

                  ],

                ),

              ),

              const SizedBox(height: 25),

              const Padding(

                padding: EdgeInsets.symmetric(horizontal: 20),

                child: Align(

                  alignment: Alignment.centerLeft,

                  child: Column(

                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [

                      Text(

                        "Selamat Pagi,",

                        style: TextStyle(

                          color: Colors.white,

                          fontSize: 20,

                        ),

                      ),

                      Text(

                        "Arman",

                        style: TextStyle(

                          color: Colors.white,

                          fontSize: 34,

                          fontWeight: FontWeight.bold,

                        ),

                      ),

                    ],

                  ),

                ),

              ),

              const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(.12),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: TextField(
  controller: searchController,
  decoration: InputDecoration(
    hintText: "Search",
    hintStyle: const TextStyle(
      color: Colors.grey,
      fontSize: 14,
    ),
    prefixIcon: const Icon(
      Icons.search,
      color: Colors.grey,
    ),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(vertical: 14),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: BorderSide.none,
    ),
  ),
  onChanged: (_) => setState(() {}),
),
                        ),
                      ),

                      const SizedBox(width: 10),

                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(.12),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.tune),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                SizedBox(
                  height: 42,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: filters.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final filter = filters[index];

                      final selected = selectedFilter == filter;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedFilter = filter;
                          });
                        },
                        child: AnimatedContainer(
  duration: const Duration(milliseconds: 180),
  padding: const EdgeInsets.symmetric(
    horizontal: 18,
    vertical: 8,
  ),
  decoration: BoxDecoration(
    color: selected
        ? const Color(0xffB8893C)
        : Colors.white,
    borderRadius: BorderRadius.circular(14),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(.08),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  ),
  child: Center(
    child: Text(
      filter,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        color: selected
            ? Colors.white
            : Colors.black87,
      ),
    ),
  ),
)
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: filteredEmployees.length,
                    itemBuilder: (context, index) {

                      final employee = filteredEmployees[index];

                      return _employeeCard(employee);

                    },

                    
                  ),
                ),

            ],

          ),

        ),

      ),

    );
  }

  Widget _employeeCard(Employee employee) {
  return Container(
    margin: const EdgeInsets.only(bottom: 18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(.12),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        // TODO:
        // Navigator.push(...)
      },
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            CircleAvatar(
              radius: 35,
              backgroundImage: NetworkImage(employee.image),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    employee.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 6),

                  Text(
                    "NIP : ${employee.nip}",
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    "Jabatan : ${employee.jabatan}",
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    "Unit : ${employee.unit}",
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Align(
                    alignment: Alignment.centerRight,
                    child: _statusBadge(employee.status),
                  ),

                ],
              ),
            ),

            PopupMenuButton(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (context) => [

                const PopupMenuItem(
                  value: "detail",
                  child: Text("Lihat Profil"),
                ),

                const PopupMenuItem(
                  value: "edit",
                  child: Text("Edit"),
                ),

                const PopupMenuItem(
                  value: "hapus",
                  child: Text("Hapus"),
                ),

              ],
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _statusBadge(String status) {



  return Container(
  margin: const EdgeInsets.only(bottom: 18),
  padding: const EdgeInsets.all(14),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(.08),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  ),
);
}

  List<Employee> get filteredEmployees {

  final keyword = searchController.text.toLowerCase();

  return employees.where((employee) {

    final matchSearch =
        employee.name.toLowerCase().contains(keyword) ||
        employee.nip.contains(keyword);

    if (!matchSearch) return false;

    switch (selectedFilter) {

      case "ASN":
        return employee.jabatan.contains("Kepala");

      case "Jabatan Struktural":
        return employee.jabatan.contains("Kepala");

      case "Jabatan Fungsional":
        return employee.jabatan.contains("Analis");

      case "P3K":
        return true;

      case "P3K Paruh Waktu":
        return true;

      case "PJLP":
        return true;

      default:
        return true;

    }

  }).toList();

}

}