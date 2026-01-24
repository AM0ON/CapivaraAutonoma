import 'package:flutter/material.dart';

class PremiumPage extends StatefulWidget {
  final VoidCallback? onAssinarMensal;
  final VoidCallback? onAssinarAnual;
  final VoidCallback? onRestaurarCompras;
  final VoidCallback? onAbrirTermos;
  final VoidCallback? onAbrirPrivacidade;

  const PremiumPage({
    super.key,
    this.onAssinarMensal,
    this.onAssinarAnual,
    this.onRestaurarCompras,
    this.onAbrirTermos,
    this.onAbrirPrivacidade,
  });

  @override
  State<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage> {
  String planoSelecionado = 'Anual';

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Text(
            'Tenha tudo na Palma da mão sem Distrações',
            style: tema.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Sem anúncios, mais relatórios e recursos avançados.',
            style: tema.textTheme.bodyMedium?.copyWith(color: Colors.black54),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _cardPlano(
                  titulo: 'Mensal',
                  preco: 'R\$ 19,90',
                  destaque: 'Cobrança mensal',
                  selecionado: planoSelecionado == 'Mensal',
                  onTap: () => setState(() => planoSelecionado = 'Mensal'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _cardPlano(
                  titulo: 'Anual',
                  preco: 'R\$ 149,90',
                  destaque: 'Economize no plano Anual',
                  selecionado: planoSelecionado == 'Anual',
                  onTap: () => setState(() => planoSelecionado = 'Anual'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _cardBeneficios(),
          const SizedBox(height: 16),

          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _assinarSelecionado,
              child: Text(planoSelecionado == 'Mensal' ? 'Assinar Mensal' : 'Assinar Anual'),
            ),
          ),

          const SizedBox(height: 10),

          SizedBox(
            height: 48,
            child: OutlinedButton(
              onPressed: widget.onRestaurarCompras,
              child: const Text('Restaurar compra'),
            ),
          ),

          const SizedBox(height: 18),
          _cardInformacoes(),
        ],
      ),
    );
  }

  void _assinarSelecionado() {
    if (planoSelecionado == 'Mensal') {
      widget.onAssinarMensal?.call();
      return;
    }
    widget.onAssinarAnual?.call();
  }

  Widget _cardPlano({
    required String titulo,
    required String preco,
    required String destaque,
    required bool selecionado,
    required VoidCallback onTap,
  }) {
    final borda = selecionado ? Colors.black : Colors.black12;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borda, width: selecionado ? 1.4 : 1),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 14,
              offset: const Offset(0, 6),
              color: Colors.black.withOpacity(0.05),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    titulo,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: borda),
                    color: selecionado ? Colors.black : Colors.transparent,
                  ),
                  child: selecionado
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              preco,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              destaque,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardBeneficios() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            blurRadius: 14,
            offset: const Offset(0, 6),
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'O que você ganha no Premium',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          _linhaBeneficio('Sem anúncios'),
          _linhaBeneficio('Relatórios completos'),
          _linhaBeneficio('Veja seus Ganhos, Despesas e Lucro Real'),
          _linhaBeneficio('Cadastre seus Clientes, Mantenha o Contato'),
          _linhaBeneficio('Exportação e impressão de relatórios'),
          _linhaBeneficio('Acesso rápido a Texto Fiscal para NFs'),
          _linhaBeneficio('Prioridade nas próximas melhorias'),
        ],
      ),
    );
  }

  Widget _linhaBeneficio(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardInformacoes() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            blurRadius: 14,
            offset: const Offset(0, 6),
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informações',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'A assinatura renova automaticamente, a menos que seja cancelada pelo usuário na loja. Você pode cancelar a qualquer momento nas configurações do Google Play.',
            style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.35),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onAbrirTermos,
                  child: const Text('Termos'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onAbrirPrivacidade,
                  child: const Text('Privacidade'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
