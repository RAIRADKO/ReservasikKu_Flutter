import 'package:flutter/material.dart';
import '../common/extensions.dart';
import '../common/app_theme.dart';

class TableCard extends StatelessWidget {
  final Map<String, dynamic> table;
  final bool isSelected;
  final VoidCallback onTap;

  const TableCard({
    super.key,
    required this.table,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelectedColor = isSelected ? AppTheme.primaryBlue : Colors.grey[300];
    final textColor = isSelected ? AppTheme.primaryBlue : AppTheme.textPrimary;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 160,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
                width: 2.5,
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: isSelected
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryBlue.withOpacity(0.1),
                          AppTheme.lightBlue,
                        ],
                      )
                    : null,
                color: isSelected ? null : Colors.white,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? AppTheme.primaryGradient
                          : LinearGradient(
                              colors: [
                                Colors.grey[300]!,
                                Colors.grey[400]!,
                              ],
                            ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isSelected ? AppTheme.primaryBlue : Colors.grey)
                              .withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'Meja ${table['table_number']}',
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${table['capacity']} orang',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (table['location'] != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      table['location'].toString().capitalize(),
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}