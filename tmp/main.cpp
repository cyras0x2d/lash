#include <fstream>
#include <iomanip>
#include <iostream>
#include <limits>
#include <openssl/evp.h>
#include <sstream>
#include <string>
#include <unordered_map>
#include <vector>

using namespace std;

class HashEngine {
private:
  unordered_map<string, string> hash_table;

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
  void auto_load_wordlist() {
    // Look for common wordlist filename variations
    vector<string> common_filenames = {
        "wordlist.txt",   "word-list.txt", "words.txt",    "rockyou.txt",
        "dictionary.txt", "common.txt",    "passwords.txt"};

    string target_file = "";
    bool file_found = false;

    // Scan the current directory for any of the common files
    for (const string &filename : common_filenames) {
      ifstream test_file(filename);
      if (test_file.is_open()) {
        target_file = filename;
        file_found = true;
        test_file.close();
        break; // Stop looking once we find a match
      }
    }

    // The friendly error message if nothing is found
    if (!file_found) {
      cout << "\n[!] I feel so empty...\n";
      cout << "[!] Please put a wordlist.txt (or rockyou.txt) right beside me "
              ":(\n\n";
      return;
    }

    // If found, proceed with loading
    ifstream file(target_file);
    string word;
    int word_count = 0;
    int hash_count = 0;

    cout << "[*] Found dictionary: " << target_file << "\n";
    cout << "[*] Generating MD5, SHA-1, and SHA-256 hashes (this will take a "
            "moment)...\n";

    while (getline(file, word)) {
      if (!word.empty() && word.back() == '\r')
        word.pop_back();

      hash_table[compute_hash(word, "MD5")] = word;
      hash_table[compute_hash(word, "SHA1")] = word;
      hash_table[compute_hash(word, "SHA256")] = word;

      word_count++;
      hash_count += 3;
    }
    cout << "[+] Loaded " << word_count << " words (" << hash_count
         << " total hashes) into memory.\n";
  }

  void lookup_hash() {
    string target_hash;
    cout << "\nEnter hash: ";
    cin >> target_hash;

    int len = target_hash.length();
    string detected_type = "Unknown";

    if (len == 32)
      detected_type = "MD5";
    else if (len == 40)
      detected_type = "SHA-1";
    else if (len == 64)
      detected_type = "SHA-256";

    if (detected_type == "Unknown") {
      cout << "[-] Warning: Length (" << len
           << ") does not match standard MD5, SHA-1, or SHA-256.\n";
    } else {
      cout << "[*] Detected format: " << detected_type << "\n";
    }

    auto it = hash_table.find(target_hash);
    if (it != hash_table.end()) {
      cout << "[+] MATCH FOUND: " << it->second << "\n";
    } else {
      cout << "[-] No match found in the database.\n";
    }
  }

  void add_word() {
    string new_word;
    cout << "\nEnter word to add: ";
    cin >> new_word;

    string md5_hash = compute_hash(new_word, "MD5");

    if (hash_table.find(md5_hash) != hash_table.end()) {
      cout << "[-] Word already exists in the database.\n";
      return;
    }

    hash_table[md5_hash] = new_word;
    hash_table[compute_hash(new_word, "SHA1")] = new_word;
    hash_table[compute_hash(new_word, "SHA256")] = new_word;

    cout << "[+] Added word and generated 3 hash variants for: " << new_word
         << "\n";
  }
};

int main() {
  HashEngine engine;

  // Call the new smart loader instead of hardcoding the string
  engine.auto_load_wordlist();

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
