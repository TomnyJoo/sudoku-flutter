class KillerConstants {
  static const int boardSize = 9;
  static const int boxSize = 3;
  
  // Cage大小：1-9格都允许
  static const int minCageSize = 1;
  static const int maxCageSize = 9;
  
  // Sum范围：根据cage大小动态计算
  // 1格: 1-9
  // 2格: 3-17 (1+2=3, 8+9=17)
  // 9格: 45 (1+2+...+9)
  static const int minCageSum = 1;
  static const int maxCageSum = 45;
  
  // 关键规则：笼子内数字绝对不能重复
  // 这是杀手数独的硬性规则之一
}
