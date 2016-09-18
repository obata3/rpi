{
  # usage
  r2 = strtonum("0x" $2)
  u = usage[r2]

  # device
  r1 = strtonum("0x" $1)
  if (u == "") {
    d = device[r1]
    if (d == "")
      d = "N/A"
  } else
    d = u

  # balance
  balance = strtonum("0x" $12 $11)

  # serial
  serial = strtonum("0x" $14 $15)

  # date
  r5 = strtonum("0x" $5); r6 = strtonum("0x" $6)
  yy = 2000 + int(r5 / 2); mm = or(and(r5, 1) * 8, int(r6 / 32)); dd = and(r6, 31)

  # area code
  ac1 = strtonum("0x" $16) / 64;
  ac2 = and(strtonum("0x" $16) / 16, 3);

  # line code
  lc1 = strtonum("0x" $7)
  lc2 = strtonum("0x" $9)

  # station code
  sc1 = strtonum("0x" $8)
  sc2 = strtonum("0x" $10)

  # time
  if (r2 == 0x46) {
    r7 = strtonum("0x" $7); r8 = strtonum("0x" $8)
    HH = int(r7 / 8); MM = or(and(r7, 0x07) * 8, int(r8 / 32)); SS = and(r8, 31) * 2

    #printf "%04d-%02d-%02d %02d:%02d:%02d %s %5d\n", yy, mm, dd, HH, MM, SS, d, balance
    printf "%d/%d %02d:%02d %s %d\n", mm, dd, HH, MM, d, balance
  } else {
    #printf "%04d-%02d-%02d --:--:-- %s %5d\n", yy, mm, dd, d, balance
    if ((r1 == 0x16 && r2 != 0x14) || r1 == 0x1d) {
      printf "%d/%d --:-- %s %d %s→%s\n", mm, dd, d, balance, station(ac1, lc1, sc1), station(ac2, lc2, sc2)
      fflush()
    } else if (r1 == 0x08 || r1 == 0x12 || (r1 == 0x16 && r2 == 0x14)) {
      printf "%d/%d --:-- %s %d %s\n", mm, dd, d, balance, station(ac1, lc1, sc1)
      fflush()
    } else {
      printf "%d/%d --:-- %s %d\n", mm, dd, d, balance
    }
  }
}

BEGIN {
  device[0x05] = "バス"
  device[0x08] = "券売機"
  device[0x12] = "券売機"
  device[0x16] = "電車"
  device[0x1d] = "電車"
  device[0xc7] = "物販"
  device[0xc8] = "自販機"
  usage[0x02]  = "チャージ"
  usage[0x14]  = "チャージ"
  usage[0x1f]  = "チャージ"
}

function station(a, b, c,  x, y) {
  if (st[a,b,c] != "")
    return st[a,b,c]
  x = sprintf("./find-station.sh %x %x %x", a, b, c)
  x | getline y
  close(x)
  return y
}
