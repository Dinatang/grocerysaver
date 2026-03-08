// Pantalla para encolar y monitorear exportaciones asincronas.
import 'dart:async';

import 'package:flutter/material.dart';

import '../services/api_config.dart';
import '../services/jobs_api.dart';

/// Interfaz de usuario para jobs de exportacion de productos.
class ExportJobsView extends StatefulWidget {
  const ExportJobsView({super.key});

  @override
  State<ExportJobsView> createState() => _ExportJobsViewState();
}

class _ExportJobsViewState extends State<ExportJobsView> {
  late final JobsApi _api;
  final TextEditingController _searchController = TextEditingController();

  Timer? _pollingTimer;
  bool _isSubmitting = false;
  bool _isChecking = false;
  String? _errorMessage;
  String? _successMessage;
  String? _cacheStatus;
  String? _jobId;
  String? _jobType;
  String? _jobStatus;
  bool _isFinished = false;
  String? _resultUrl;
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    _api = JobsApi(ApiConfig.baseUrl);
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Encola un nuevo job y arranca el polling automatico.
  Future<void> _startExport() async {
    _pollingTimer?.cancel();
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _successMessage = null;
      _cacheStatus = null;
      _resultUrl = null;
      _result = null;
      _isFinished = false;
    });

    try {
      final data = await _api.enqueueExportProductsJob(
        search: _searchController.text,
      );
      final job = _extractJob(data);

      if (!mounted) return;
      setState(() {
        _jobId = _text(job['job_id']);
        _jobType = _text(job['job_type']);
        _jobStatus = _text(job['status'], fallback: 'queued');
        _cacheStatus = _api.lastCacheStatus;
        _successMessage = _text(
          data['message'],
          fallback: 'Job encolado correctamente.',
        );
      });

      _startPolling();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  /// Consulta periodicamente el estado del job mientras no termine.
  void _startPolling() {
    _pollingTimer?.cancel();
    final currentJobId = _jobId;
    if (currentJobId == null || currentJobId.isEmpty) return;

    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      await _checkJobStatus(showLoader: false);
      final status = (_jobStatus ?? '').toLowerCase();
      if (status == 'completed' || status == 'failed' || _isFinished) {
        _pollingTimer?.cancel();
      }
    });
  }

  /// Consulta manual o automaticamente el estado del job actual.
  Future<void> _checkJobStatus({bool showLoader = true}) async {
    final currentJobId = _jobId;
    if (currentJobId == null || currentJobId.isEmpty || _isChecking) return;

    if (showLoader) {
      setState(() {
        _isChecking = true;
        _errorMessage = null;
      });
    } else {
      _isChecking = true;
    }

    try {
      final data = await _api.getJobStatus(currentJobId);
      final job = _extractJob(data);
      final status = _text(job['status'], fallback: _jobStatus ?? 'pending');
      final finished = _asBool(data['is_finished']) || _isTerminal(status);

      if (!mounted) return;
      setState(() {
        _jobStatus = status;
        _resultUrl = _textOrNull(job['result_url']);
        _result = job['result'] is Map<String, dynamic>
            ? job['result'] as Map<String, dynamic>
            : null;
        _isFinished = finished;
        _cacheStatus = _api.lastCacheStatus;
        if (status.toLowerCase() == 'completed') {
          _successMessage = 'Exportacion completada.';
        }
      });

      if (finished) {
        _pollingTimer?.cancel();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      } else {
        _isChecking = false;
      }
    }
  }

  /// Extrae el objeto `job` y valida que exista en la respuesta.
  Map<String, dynamic> _extractJob(Map<String, dynamic> data) {
    final job = data['job'];
    if (job is Map<String, dynamic>) {
      return job;
    }
    throw JobsApiException('La respuesta no contiene el objeto job.');
  }

  /// Convierte cualquier valor a texto con fallback opcional.
  String _text(dynamic value, {String fallback = ''}) {
    final text = (value ?? '').toString().trim();
    return text.isEmpty ? fallback : text;
  }

  /// Devuelve `null` cuando el valor no aporta texto util.
  String? _textOrNull(dynamic value) {
    final text = _text(value);
    return text.isEmpty ? null : text;
  }

  /// Interpreta flags booleanos serializados como texto o numero.
  bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = (value ?? '').toString().toLowerCase();
    return text == 'true' || text == '1' || text == 'yes';
  }

  /// Determina si el job ya no necesita seguir en polling.
  bool _isTerminal(String status) {
    final normalized = status.toLowerCase();
    return normalized == 'completed' || normalized == 'failed';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exportar productos')),
      body: RefreshIndicator(
        onRefresh: () => _checkJobStatus(showLoader: false),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            _HeroCard(cacheStatus: _cacheStatus),
            const SizedBox(height: 12),
            _buildRequestCard(),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              _MessageBox(
                message: _errorMessage!,
                color: const Color(0xFFFCEAEA),
                textColor: const Color(0xFFAC2E2E),
              ),
            ],
            if (_successMessage != null) ...[
              const SizedBox(height: 12),
              _MessageBox(
                message: _successMessage!,
                color: const Color(0xFFE9F5ED),
                textColor: const Color(0xFF20573A),
              ),
            ],
            const SizedBox(height: 12),
            _buildStatusCard(),
          ],
        ),
      ),
    );
  }

  /// Formulario para encolar una nueva exportacion.
  Widget _buildRequestCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE3E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Encolar exportacion',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A242D),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Filtro de busqueda',
              hintText: 'Ej. leche',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isSubmitting ? null : _startExport,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.file_download_outlined),
              label: Text(_isSubmitting ? 'Encolando...' : 'Exportar productos'),
            ),
          ),
        ],
      ),
    );
  }

  /// Tarjeta con el resumen actual del job en seguimiento.
  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE3E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Estado del job',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A242D),
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: (_jobId == null || _isChecking)
                    ? null
                    : () => _checkJobStatus(),
                icon: _isChecking
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync_rounded),
                label: const Text('Consultar'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _StatusLine(label: 'Job ID', value: _jobId ?? 'Sin job'),
          _StatusLine(label: 'Tipo', value: _jobType ?? '-'),
          _StatusLine(label: 'Estado', value: _jobStatus ?? '-'),
          _StatusLine(
            label: 'Finalizado',
            value: _isFinished ? 'Si' : 'No',
          ),
          if (_resultUrl != null)
            _StatusLine(label: 'Archivo', value: _resultUrl!),
          if (_result != null && _result!.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text(
              'Resultado',
              style: TextStyle(
                color: Color(0xFF42505B),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            ..._result!.entries.map(
              (entry) => _StatusLine(
                label: entry.key,
                value: entry.value?.toString() ?? '',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Cabecera visual del modulo con estado de cache opcional.
class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.cacheStatus});

  final String? cacheStatus;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF245E44), Color(0xFF2F7D57), Color(0xFF4DA670)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 30),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Encola la exportacion y consulta su progreso sin bloquear la app.',
                  style: TextStyle(
                    color: Color(0xFFE2F6EA),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (cacheStatus != null) ...[
            const SizedBox(height: 10),
            Text(
              'Cache backend: $cacheStatus',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Fila simple clave-valor para el estado del job.
class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 86,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Color(0xFF42505B),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF42505B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Caja de mensajes de exito o error.
class _MessageBox extends StatelessWidget {
  const _MessageBox({
    required this.message,
    required this.color,
    required this.textColor,
  });

  final String message;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
