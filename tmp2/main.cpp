#include <iostream>
using namespace std;
/* Libraries in here*/

int main() {
  int op;
  cout << "LASH \n";
  cout << "1. Hash Lookup \n";
  cout << "2. Add Wordlist \n";
  cout << "3. Exit \n";

  cout << "Choose:";
  cin >> op;
  switch (op) {
  case 1:
    cout << "Hash ";
    break;

  case 2:
    cout << "add word";

  case 3:
    return 0;

  default:
    break;
  }
}
