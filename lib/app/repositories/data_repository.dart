import 'package:flutter/foundation.dart';
import 'package:flutter_project_covid/app/repositories/endpoints_data.dart';
import 'package:flutter_project_covid/app/services/api.dart';
import 'package:flutter_project_covid/app/services/api_service.dart';
import 'package:flutter_project_covid/app/services/data_cache_services.dart';
import 'package:flutter_project_covid/app/services/endpoint_data.dart';
import 'package:http/http.dart';

class DataRepository {
  DataRepository({@required this.apiService, @required this.dataCacheService});
  final APIService apiService;
  final DataCacheService dataCacheService;

  String _accessToken;

  Future<EndpointData> getEndpointData(Endpoint endpoint) async =>
      await _getDataRefreshingToken<EndpointData>(
        onGetData: () => apiService.getEndpointData(
            accessToken: _accessToken, endpoint: endpoint),
      );

  EndpointsData getAllEndpointsCacheData() => dataCacheService.getData();

  Future<EndpointsData> getAllEndpointsData() async {
    // no argument neede as reading all endpoints at once
    final endpointsData = await _getDataRefreshingToken<EndpointsData>(
      // onGetData: () => _getAllEndpointsData(), or
      onGetData: _getAllEndpointsData, // both have no arguments
    );
    await dataCacheService.setData(endpointsData);
    return endpointsData;
  }

  Future<T> _getDataRefreshingToken<T>({Future<T> Function() onGetData}) async {
    // generics and function arguments => more reusable code
    // no argument neede as reading all endpoints at once
    try {
      if (_accessToken == null) {
        _accessToken = await apiService.getAccessToken();
      }
      return await onGetData();
    } on Response catch (response) {
      // if unauthorised, get access token again
      if (response.statusCode == 401) {
        _accessToken = await apiService.getAccessToken();
        return await onGetData();
      }
      rethrow;
    }
  }

  Future<EndpointsData> _getAllEndpointsData() async {
    final values = await Future.wait([
      // takes list of futures as input argument and returns single future with list of all the responses
      apiService.getEndpointData(
          accessToken: _accessToken, endpoint: Endpoint.cases),
      apiService.getEndpointData(
          accessToken: _accessToken, endpoint: Endpoint.casesSuspected),
      apiService.getEndpointData(
          accessToken: _accessToken, endpoint: Endpoint.casesConfirmed),
      apiService.getEndpointData(
          accessToken: _accessToken, endpoint: Endpoint.deaths),
      apiService.getEndpointData(
          accessToken: _accessToken, endpoint: Endpoint.recovered),
    ]);
    return EndpointsData(
      values: {
        Endpoint.cases: values[0],
        Endpoint.casesSuspected: values[1],
        Endpoint.casesConfirmed: values[2],
        Endpoint.deaths: values[3],
        Endpoint.recovered: values[4],
      },
    );
  }
}
