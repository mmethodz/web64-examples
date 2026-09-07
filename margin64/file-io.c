#include "margin64.h"
#include <web64/disk.h>
#include <cbm.h>

/* Three separate native errors: KERNAL call, READST transport, DOS channel 15.
 * Channel 15 stays open for one operation. Channel 2 is our data stream.
 * Select once per stream, not once per byte: ordinary 1541 IEC is already slow.
 * No browser filesystem, hidden loader, overwrite-save or destructive Open. */
char document_name[17];
uint8_t disk_device = 8;
static char requested_name[17], temporary_name[17], backup_name[17];
uint8_t file_io_failed, file_io_eof, file_io_value;
uint16_t file_crc;
uint8_t file_dos_code;
static uint8_t name_serial;
static uint8_t plain_mode, ask_save_as;
uint16_t file_io_count;
uint16_t file_output_position;
uint16_t file_directory_blocks;
/* Measured byte kernels: explicit ordinary C/ASM ABI, no resident C frames
 * or 16-bit boolean scaffolding for every file byte. Policy stays below. */
uint8_t asm_file_stream_get(void);
_fastcall void file_stream_put(uint8_t value);
_fastcall void file_crc_byte(uint8_t value);
_fastcall uint8_t file_native_byte(uint8_t value);
_fastcall uint8_t file_plain_byte(uint8_t value);
void file_copy_name(char *to, const char *from);
void file_number_name(char *name, uint8_t serial);
_fastcall uint8_t file_name_length(const char *name);
_fastcall uint8_t file_name_valid(const char *name);
_fastcall uint8_t file_hex_digit(uint8_t value);
_fastcall uint8_t file_next_output(uint8_t plain);
uint8_t file_valid_header(void);
void file_make_header(void);
_fastcall uint8_t file_read_document(uint8_t plain, uint8_t verify);
uint8_t file_dos_status(void);
uint8_t file_open_command(const char *name, uint8_t writing);
uint8_t file_open_data(const char *name, uint8_t writing);
_fastcall void file_write_document(uint8_t plain);
uint8_t file_rename(const char *new_name, const char *old_name);
uint8_t file_directory_line(void);
#define io_failed file_io_failed
#define io_eof file_io_eof
#define io_value file_io_value
#define io_crc file_crc
#define stream_get asm_file_stream_get
#define stream_put file_stream_put
#define crc_byte file_crc_byte
#define native_byte file_native_byte
#define plain_byte file_plain_byte
#define copy_name file_copy_name
#define name_length file_name_length
#define valid_name file_name_valid
#define hex_digit file_hex_digit
#define output_byte file_next_output
#define output_position file_output_position
#define io_count file_io_count
#define valid_header file_valid_header
#define make_header file_make_header
#define read_document file_read_document
#define read_dos file_dos_status
#define dos_code file_dos_code
#define rename_file file_rename
#define open_data file_open_data
#define FILE_HEADER IO_BUFFER
#define DOS_TEXT ((uint8_t *)0x6920)
#define DOS_COMMAND ((uint8_t *)0x6950)

/* DOS status is a distinct stream. Its native kernel records raw carry and
 * READST failures in io_failed; SDK family latches are not overwritten. */
static uint8_t begin_disk(void) {
    static uint8_t status;
    io_failed = 0;
    dos_code = 0;
    status = web64_file_open("", 0, 15, disk_device, 15);
    if (status != 0 || web64_disk_last_error() != 0) { io_failed = 1; return 0; }
    read_dos();                 /* Consume old status/power-up banner. */
    dos_code = 0;
    return !io_failed;
}

static void end_disk(void) {
    web64_file_close(2);
    web64_file_close(15);
    cbm_k_clrchn();
}

static void close_data(void) {
    static uint8_t status;
    status = web64_file_close(2);
    if ((status & 191) != 0) io_failed = 1;
}

static uint8_t file_exists(const char *name) {
    static uint8_t exists;
    exists = open_data(name, 0);
    close_data();
    if (!exists && dos_code == 62 && !io_failed) { dos_code = 0; return 0; }
    if (!exists) io_failed = 1;
    return 1;
}

/* The disk has at most 144 entries; bounded probing can refuse safely.
 * Never scratch an old temporary/backup to make a chosen name available. */
static uint8_t unused_name(char *name, uint8_t kind) {
    static uint8_t tries;
    copy_name(name, kind == 'B' ? "M64-BACK-00" : "M64-TEMP-00");
    for (tries = 0; tries < 32; tries++) {
        name_serial++;
        file_number_name(name, name_serial);
        if (!file_exists(name)) return 1;
        if (io_failed) return 0;
    }
    io_failed = 5;
    return 0;
}

/* UI labels are encoded by Web64 for the mixed-case ROM screen. Native
 * filenames, DOS commands and format bytes above remain ASCII/PETSCII. */
#pragma charset("screencode_mixed")
static void file_error(void) {
    static const char *message;
    message = "DISK ERROR - CHECK DEVICE/DISK";
    if (dos_code == 26) message = "WRITE PROTECTED - TEXT IS SAFE";
    else if (dos_code == 62) message = "FILE NOT FOUND - TEXT IS SAFE";
    else if (dos_code == 63) message = "FILE EXISTS - NO FILE REPLACED";
    else if (dos_code == 72) message = "DISK FULL - ORIGINAL IS SAFE";
    else if (io_failed == 2) message = "INVALID FILE - TEXT UNCHANGED";
    else if (io_failed == 3) message = "FILE TOO LARGE - TEXT UNCHANGED";
    else if (io_failed == 5) message = "NO TEMP NAME - TRY ANOTHER DISK";
    ui_message(message);
}

static void open_document(void);
void file_open_dialog(uint8_t plain) {
    plain_mode = plain;
    open_document();
}

static void open_document(void) {
    static uint8_t ok;
    if (doc.modified && !ui_confirm("DISCARD UNSAVED EDITS IF OPEN SUCCEEDS?")) return;
    copy_name(requested_name, document_name);
    if (!ui_prompt(plain_mode ? "IMPORT PETSCII FILE" : "OPEN MARGIN64 DOCUMENT", requested_name, 16)) return;
    if (!valid_name(requested_name)) { ui_message("NAME: 1 TO 16 CHARACTERS"); return; }
    view_refresh();
    asm_cursor_hide();
    ui_message("READING - CURRENT DOCUMENT SAFE");
    ok = begin_disk();
    if (ok) ok = open_data(requested_name, 0);
    if (ok) ok = asm_cold_invalidate();
    if (ok) ok = read_document(plain_mode, 0);
    close_data();
    if (ok && read_dos() != 0) ok = 0;
    end_disk();
    if (!ok || io_failed) { file_error(); return; }
    bank_length = io_count;
    asm_commit_candidate();
    doc_adopt(io_count);
    if (!plain_mode) {
        editor_width = FILE_HEADER[12]; print_width = FILE_HEADER[13];
        print_lines = FILE_HEADER[14]; print_margin = FILE_HEADER[15]; print_spacing = FILE_HEADER[16];
        copy_name(document_name, requested_name);
    } else { document_name[0] = 0; doc.modified = 1; }
    asm_clear_screen();
    view_invalidate();
    view_refresh();
    ui_message(plain_mode ? "PETSCII IMPORTED - SAVE AS NATIVE" : "DOCUMENT OPENED");
}

/* Names remain visible after errors: a power failure cannot be rolled back
 * atomically by Commodore DOS. Keep the old file as an explicit backup. */
static void recovery_names(void) {
    static uint8_t key;
    asm_clear_screen();
    ui_write(2, 2, "SAVE RECOVERY - KEEP THESE FILES\377\377\377\377VERIFIED CANDIDATE:\377\377\377\377PREVIOUS DOCUMENT:\377\377\377\377\377DO NOT DELETE YOUR ONLY VALID COPY.\377\377\377\377ANY KEY: RETURN TO CURRENT DOCUMENT");
    ui_petscii(7, 2, temporary_name);
    if (backup_name[0]) ui_petscii(11, 2, backup_name);
    do { key = asm_key(); } while (!key);
    view_redraw(); view_refresh();
}

static void save_document(void);
void file_save_dialog(uint8_t save_as, uint8_t plain) {
    plain_mode = plain;
    ask_save_as = save_as;
    save_document();
}

static void save_document(void) {
    static uint8_t existing, n, promoted;
    copy_name(requested_name, document_name);
    if (plain_mode) requested_name[0] = 0;
    if (plain_mode || ask_save_as || !requested_name[0]) {
        if (!ui_prompt(plain_mode ? "EXPORT PETSCII AS" : "SAVE DOCUMENT AS", requested_name, 16)) return;
    }
    if (!valid_name(requested_name)) { ui_message("NAME: 1 TO 16 CHARACTERS"); return; }
    view_refresh();
    asm_cursor_hide();
    ui_message("SAVING VERIFIED TEMP FILE...");
    temporary_name[0] = 0; backup_name[0] = 0;
    promoted = 0;
    if (!begin_disk()) goto save_failed;
    existing = file_exists(requested_name);
    if (io_failed) goto save_failed;
    if (existing) {
        cbm_k_clrchn();
        if (!ui_confirm("REPLACE FILE, KEEP PREVIOUS AS BACKUP?")) { end_disk(); return; }
        view_refresh();
        asm_cursor_hide();
        ui_message("SAVING VERIFIED TEMP FILE...");
    }
    if (!unused_name(temporary_name, 0x54)) goto save_failed;
    if (existing && !unused_name(backup_name, 0x42)) goto save_failed;
    if (!open_data(temporary_name, 1)) goto save_failed;
    file_write_document(plain_mode);
    close_data();
    if (read_dos() != 0 || io_failed) goto save_failed;
    if (!open_data(temporary_name, 0)) goto save_failed;
    if (!read_document(plain_mode, 1)) goto save_failed;
    close_data();
    if (read_dos() != 0 || io_failed) goto save_failed;
    if (existing) {
        if (!rename_file(backup_name, requested_name)) goto save_failed;
        promoted = 1;
    }
    if (!rename_file(requested_name, temporary_name)) goto save_failed;
    end_disk();
    if (!plain_mode) { copy_name(document_name, requested_name); doc.modified = 0; }
    if (existing) {
        copy_name((char *)DOS_TEXT, "BACKUP: ");
        copy_name((char *)DOS_TEXT + 8, backup_name);
        for (n = 8; DOS_TEXT[n]; n++) DOS_TEXT[n] = ui_petscii_code(DOS_TEXT[n]);
        ui_message((const char *)DOS_TEXT);
    } else ui_message(plain_mode ? "EXPORTED; NATIVE FILE UNCHANGED" : "DOCUMENT SAVED AND VERIFIED");
    return;
save_failed:
    end_disk();
    /* No destructive rollback. Both recoverable names remain valid if
     * the second rename failed, including a removal/unready-disk case. */
    if (promoted) recovery_names();
    file_error();
}

/* Directory is streamed as BASIC linked lines; no LOAD over program/document.
 * A bounded page is shown without storing the complete directory in RAM. */
void file_directory(void) {
    static uint8_t ok, row, key, status;
    asm_cursor_hide();
    ok = begin_disk();
    if (ok) {
        status = web64_file_open("$", 1, 2, disk_device, 0);
        ok = status == 0 && web64_disk_last_error() == 0;
        if (ok) ok = read_dos() == 0;
        if (ok) { status = cbm_k_chkin(2); ok = status == 0 && cbm_k_last_error() == 0; }
    }
    if (!ok) { end_disk(); file_error(); return; }
    io_eof = 0;
    if (!stream_get() || !stream_get()) io_failed = 1;
    row = 3;
    asm_clear_screen();
    ui_write(0, 2, "DISK DIRECTORY"); ui_number(0, 20, disk_device, 2);
    while (!io_failed && file_directory_line()) {
        ui_number(row, 1, file_directory_blocks, 3);
        ui_petscii(row, 6, (const char *)DOS_TEXT);
        row++;
        if (row >= 22) {
            cbm_k_clrchn();
            ui_write(24, 1, "SPACE: NEXT PAGE  RUN/STOP: CLOSE");
            do { key = asm_key(); } while (!key);
            if (key == 3 || key == 27) break;
            status = cbm_k_chkin(2);
            if (status != 0 || cbm_k_last_error() != 0) { io_failed = 1; break; }
            asm_clear_screen(); ui_write(0, 2, "DISK DIRECTORY"); row = 3;
        }
    }
    end_disk();
    ui_write(24, 1, "ANY KEY: RETURN TO DOCUMENT");
    do { key = asm_key(); } while (!key);
    view_redraw(); view_refresh();
    if (io_failed) file_error(); else ui_message("DIRECTORY CLOSED");
}
