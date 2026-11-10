-- =============================================================================
-- KINETIX — Correção: tempo real da tabela de usuários
-- Para quem já rodou o schema de 10/11. Rode no SQL Editor do Supabase.
--
-- A tabela "profiles" tinha ficado fora da publicação do Realtime. O canal da
-- tela Gestão → Usuários falhava, o app recarregava a lista em loop e a tela
-- ficava piscando.
-- =============================================================================
do $$
begin
  alter publication supabase_realtime add table public.profiles;
exception when duplicate_object then null;
end $$;
