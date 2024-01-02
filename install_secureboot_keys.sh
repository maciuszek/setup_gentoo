#!/bin/bash
# Assumes secure boot keys in bios/uefi have been cleared (confirm keys are cleared with `efi-readvar`)

cd /etc/efikeys

efi-updatevar -e -f old_dbx.esl dbx
efi-updatevar -e -f compound_db.esl db
efi-updatevar -e -f compound_KEK.esl KEK

efi-updatevar -f PK.auth PK

efi-readvar -v PK -o new_PK.esl
efi-readvar -v KEK -o new_KEK.esl
efi-readvar -v db -o new_db.esl
efi-readvar -v dbx -o new_dbx.esl