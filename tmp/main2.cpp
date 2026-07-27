#include <fstream>
#include <iomanip>
#include <iostream>
#include <limits>
#include <openssl/evp.h>
#include <sstream>
#include <string>
#include <unordered_map>

using namespace std;

class HashEngine {
private:
  // The core hash table: Key = Hash, Value = Plaintext
  unordered_map<string, string> hash_table;

  // OpenSSL hashing function
  string compute_hash(const string &input, const string &algorithm) {
    EVP_MD_CTX *context = EVP_MD_CTX_new();
    const EVP_MD *md = EVP_get_digestbyname(algorithm.c_str());

    if (md == nullptr)
      return "";

    unsigned char md_value[EVP_MAX_MD_SIZE];
    unsigned int md_len;

    EVP_DigestInit_ex(context, md, nullptr);
    EVP_DigestUpdate(context, input.c_str(), input.length());
    EVP_DigestFinal_ex(context, md_value, &md_len);
    EVP_MD_CTX_free(context);

    stringstream ss;
    for (unsigned int i = 0; i < md_len; i++) {
      ss << hex << setw(2) << setfill('0') << (int)md_value[i];
    }
    return ss.str();
  }

public:
  // Load wordlist into the hash map
  void load_wordlist(const string &filepath) {
    ifstream file(filepath);
    if (!file.is_open()) {
      cout << "[!] Could not open wordlist: " << filepath << "\n";
      return;
    }

    string word;
    int count = 0;
    cout << "[*] Hashing wordlist (this may take a moment)...\n";

    while (getline(file, word)) {
      // Trim carriage returns if the file comes from Windows
      if (!word.empty() && word.back() == '\r')
        word.pop_back();

      // Using MD5 for the wordlist by default
      string hash = compute_hash(word, "MD5");
      hash_table[hash] = word;
      count++;
    }
    cout << "[+] Loaded " << count << " hashes into memory.\n";
  }

  void lookup_hash() {
    string target_hash;
    cout << "\nEnter hash: ";
    cin >> target_hash;

    auto it = hash_table.find(target_hash);
    if (it != hash_table.end()) {
      cout << "\n[+] MATCH FOUND: " << it->second << "\n";
    } else {
      cout << "\n[-] No match found in the database.\n";
    }
  }

  void add_word() {
    string new_word;
    cout << "\nEnter word to add: ";
    cin >> new_word;

    string hash = compute_hash(new_word, "MD5");

    // Prevent duplicate work
    if (hash_table.find(hash) != hash_table.end()) {
      cout << "[-] Word already exists in the database.\n";
      return;
    }

    hash_table[hash] = new_word;
    cout << "[+] Added -> Hash: " << hash << " | Word: " << new_word << "\n";
  }
};

int main() {
  HashEngine engine;

  // Auto-load wordlist if it exists in the same directory
  engine.load_wordlist("wordlist.txt");

  int op = 0;
  while (op != 3) {
    cout << "\n=== LASH === \n";
    cout << "1. Hash Lookup \n";
    cout << "2. Add Word \n";
    cout << "3. Exit \n";
    cout << "Choose: ";

    cin >> op;

    if (cin.fail()) {
      cin.clear();
      cin.ignore(numeric_limits<streamsize>::max(), '\n');
      cout << "Invalid input.\n";
      continue;
    }

    switch (op) {
    case 1:
      engine.lookup_hash();
      break;
    case 2:
      engine.add_word();
      break;
    case 3:
      cout << "Exiting LASH...\n";
      break;
    default:
      cout << "Invalid option.\n";
      break;
    }
  }

  return 0;
}
