# OSRS Translate Translations

Arquivos de traducao baixados dinamicamente pelo plugin OSRS Translate PT-BR.

## Estrutura

```text
manifest.json
pt-BR/
  translations.json
  translations_skills.json
  translations_quests.json
  translations_items.json
  translations_menu.json
  translations_overhead.json
  translations_game_message.json
  translations_welcome.json
  translations_settings.json
scripts/
  update-manifest.ps1
```

Cada idioma deve ter sua propria pasta e conter o conjunto completo de arquivos.
O plugin somente ativa uma versao depois de validar todos os SHA-256 declarados no
manifesto.

## Publicar uma atualizacao

1. Atualize os JSONs na pasta do idioma.
2. Execute:

```powershell
.\scripts\update-manifest.ps1 -Version "2026.07.31.1"
```

3. Revise e envie os JSONs e o `manifest.json` juntos para a branch `main`.

Use uma versao nova em cada publicacao. O script calcula os hashes e preserva
automaticamente todos os idiomas presentes no repositorio.
